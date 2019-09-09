#!/bin/bash
#
# Deploy to AWS Elastic Beanstalk, http://aws.amazon.com/elasticbeanstalk/
# Required globals:
#   AWS_ACCESS_KEY_ID
#   AWS_SECRET_ACCESS_KEY
#   AWS_DEFAULT_REGION
#   APPLICATION_NAME
#   ENVIRONMENT_NAME
#   ZIP_FILE
#
# Optional globals:
#
#   S3_BUCKET (default: ${APPLICATION_NAME}-elasticbeanstalk-deployment)
#   VERSION_LABEL (default: ${APPLICATION_NAME}-${BITBUCKET_BUILD_NUMBER}-${BITBUCKET_COMMIT:0:8})
#   DESCRIPTION (default: "")
#   WAIT (default: false)
#   WAIT_INTERVAL (default: 10)
#   DEBUG (default: false)

source "$(dirname "$0")/common.sh"

# mandatory variables
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:?'You need to configure the AWS_ACCESS_KEY_ID variable!'}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:?'You need to configure the AWS_SECRET_ACCESS_KEY variable!'}
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:?'You need to configure the AWS_DEFAULT_REGION variable!'}
APPLICATION_NAME=${APPLICATION_NAME:?'You need to configure the APPLICATION_NAME variable!'}

VALID_FILE_EXTENSIONS='zip jar war'

COMMAND=${COMMAND:="all"}

AWS_DEBUG_ARGS=""
if [[ "${DEBUG}" == "true" ]]; then
    info "Enabling debug mode."
    AWS_DEBUG_ARGS="--debug"
fi

if ! [[ "$COMMAND" =~ ^(deploy-only|upload-only|all)$ ]]; then 
    fail "Invalid COMMAND value. Possible values are deploy-only, upload-only, all." ; 
fi

if [[ "$COMMAND" == "upload-only" || "$COMMAND" == "all" ]]; then
    ZIP_FILE=${ZIP_FILE:?'You need to configure the ZIP_FILE variable!'}
    ZIP_FILE_NAME=$(basename -- "${ZIP_FILE}")
    # return as dot_extension "zip" for "filename.zip" or "filename" for "filename"
    if [[ "${ZIP_FILE_NAME}" == "${ZIP_FILE_NAME##*.}" ]];then
        # no extension provided
        ZIP_FILE_EXTENSION=''
    else
        # dot_extension
        ZIP_FILE_EXTENSION=".${ZIP_FILE_NAME##*.}"
    fi

    # default value
    IS_VALID_EXTENSION='false'

    # check valid extension
    for value in ${VALID_FILE_EXTENSIONS}
        do
            if [[ "${ZIP_FILE_EXTENSION}" == ${value} ]]; then
                IS_VALID_EXTENSION='true'
            fi
        done

    if [[ "${IS_VALID_EXTENSION}" == 'false' ]]; then
        info "The application source bundle doesn't have a known file extension (zip, jar or war). This might cause some issues."
    fi
fi

if [[ "$COMMAND" == "deploy-only" || "$COMMAND" == "all" ]]; then
    ENVIRONMENT_NAME=${ENVIRONMENT_NAME:?'You need to configure the ENVIRONMENT_NAME variable!'}
fi

# default variables
S3_BUCKET=${S3_BUCKET:=${APPLICATION_NAME}-elasticbeanstalk-deployment}
VERSION_LABEL=${VERSION_LABEL:=${APPLICATION_NAME}-${BITBUCKET_BUILD_NUMBER}-${BITBUCKET_COMMIT:0:8}}
WAIT=${WAIT:="false"}
WAIT_INTERVAL=${WAIT_INTERVAL:=10}
DESCRIPTION=${DESCRIPTION:="Application version create from https://bitbucket.org/${BITBUCKET_REPO_OWNER}/${BITBUCKET_REPO_SLUG}/addon/pipelines/home#!/results/${BITBUCKET_BUILD_NUMBER}"}

# local variables
VERSION_LABEL=${VERSION_LABEL:0:50}

debug "COMMAND = $COMMAND"

if [[ "$COMMAND" == "upload-only" || "$COMMAND" == "all" ]]; then

    s3_key="${APPLICATION_NAME}/${VERSION_LABEL}${ZIP_FILE_EXTENSION}"

    info "Uploading to s3 bucket: ${S3_BUCKET}..."
    aws s3 cp "${ZIP_FILE}" "s3://${S3_BUCKET}/${s3_key}" ${AWS_DEBUG_ARGS}

    success "Artifact uploaded successfully to s3://${S3_BUCKET}/${s3_key}"

    info "Creating application version in Elastic Beanstalk..."
    aws elasticbeanstalk create-application-version --application-name "${APPLICATION_NAME}" --version-label "${VERSION_LABEL}" --description "${DESCRIPTION}" --source-bundle "S3Bucket=${S3_BUCKET},S3Key=${s3_key}" ${AWS_DEBUG_ARGS}

    success "Application version ${VERSION_LABEL} successfully created in Elastic Beanstalk."
fi

if [[ "$COMMAND" == "deploy-only" || "$COMMAND" == "all" ]]; then

    info "Updating environment in Elastic Beanstalk..."
    aws elasticbeanstalk update-environment --environment-name "${ENVIRONMENT_NAME}" --version-label "${VERSION_LABEL}" ${AWS_DEBUG_ARGS}

    # check if the deployment was successful
    function check_environment() {
      aws elasticbeanstalk describe-environments --application-name "${APPLICATION_NAME}" --environment-names "${ENVIRONMENT_NAME}" ${AWS_DEBUG_ARGS}
    }

    # Get environment details
    environment_details=$(check_environment)
    environment_id=$(echo "$environment_details" | jq -r '.Environments[0].EnvironmentId')
    url=$(echo "$environment_details" | jq -r '.Environments[0].CNAME')
    version=$(echo "$environment_details" | jq -r '.Environments[0].VersionLabel')

    info "Deploying to environment \"${ENVIRONMENT_NAME}\". Previous version: \"${version}\" -> New version: \"${VERSION_LABEL}\"."
    success "Deployment triggered successfully. URL: http://${url}"
    info "You can follow your deployment at https://console.aws.amazon.com/elasticbeanstalk/home?region=${AWS_DEFAULT_REGION}#/environment/dashboard?applicationName=${APPLICATION_NAME}&environmentId=${environment_id}"

    if [[ "$WAIT" == "true" ]]; then
        info "Checking deployment status in Elastic Beanstalk..."

        count=1
        while  [ -z "${status}" ] || [ "${status}" == "Launching" ] || [ "${status}" == "Updating" ]; do
            sleep ${WAIT_INTERVAL}
            environment_details=$(check_environment)
            debug "Checking environment status. Attempt $count: $environment_details"
            status=$(echo "$environment_details" | jq -r '.Environments[0].Status')
            ((count++))
        done

        health=$(echo "$environment_details" | jq -r '.Environments[0].Health')
        version=$(echo "$environment_details" | jq -r '.Environments[0].VersionLabel')

        if [ "$version" != "$VERSION_LABEL" ]; then
            fail "Deployment failed. Environment \"${ENVIRONMENT_NAME}\" is running a different version \"${version}\"."
        fi

        if [ "${health}" == "Green" ] || [ "${health}" == "Yellow" ]; then
            info "Environment \"${ENVIRONMENT_NAME}\" is now running version \"${version}\" with status \"${status}\"."
            success "Deployment successful. URL: http://${url}"
        else
            fail "Deployment failed. Environment \"${ENVIRONMENT_NAME}\" is ${health}."
        fi
    fi
fi
