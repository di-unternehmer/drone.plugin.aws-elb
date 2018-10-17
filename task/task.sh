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
#   S3_BUCKET (default: ${APPLICATION_NAME}-elasticbeanstalk-deployment})
#   VERSION_LABEL (default: ${APPLICATION_NAME}-${BITBUCKET_BUILD_NUMBER}-${BITBUCKET_COMMIT:0:8}
#   WAIT (default: false)
#   DEBUG (default: false)

source "$(dirname "$0")/common.sh"

# mandatory variables
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:?'You need to configure the AWS_ACCESS_KEY_ID environment variable!'}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:?'You need to configure the AWS_SECRET_ACCESS_KEY environment variable!'}
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:?'You need to configure the AWS_DEFAULT_REGION environment variable!'}
APPLICATION_NAME=${APPLICATION_NAME:?'You need to configure the APPLICATION_NAME environment variable!'}

COMMAND=${COMMAND:="all"}

if [[ "$COMMAND" == "upload-only" || "$COMMAND" == "all" ]]; then
    ZIP_FILE=${ZIP_FILE:?'You need to configure the ZIP_FILE environment variable!'}
fi
if [[ "$COMMAND" == "deploy-only" || "$COMMAND" == "all" ]]; then
    ENVIRONMENT_NAME=${ENVIRONMENT_NAME:?'You need to configure the ENVIRONMENT_NAME environment variable!'}
fi

# default variables
S3_BUCKET=${S3_BUCKET:=${APPLICATION_NAME}-elasticbeanstalk-deployment}
VERSION_LABEL=${VERSION_LABEL:=${APPLICATION_NAME}-${BITBUCKET_BUILD_NUMBER}-${BITBUCKET_COMMIT:0:8}}
WAIT=${WAIT:="false"}

# local variables
VERSION_LABEL=${VERSION_LABEL:0:50}
WAIT_INTERVAL=10

debug "COMMAND = $COMMAND"

if [[ "$COMMAND" == "upload-only" || "$COMMAND" == "all" ]]; then

    info "Uploading to s3 bucket: ${S3_BUCKET}..."
    aws s3 cp "${ZIP_FILE}" "s3://${S3_BUCKET}/${VERSION_LABEL}.zip"

    success "Artifact uploaded successfully to s3://${S3_BUCKET}/${VERSION_LABEL}.zip"

    info "Creating application version in Elastic Beanstalk..."
    aws elasticbeanstalk create-application-version --application-name "${APPLICATION_NAME}" --version-label "${VERSION_LABEL}" --source-bundle "S3Bucket=${S3_BUCKET},S3Key=${VERSION_LABEL}.zip"

    success "Application version ${VERSION_LABEL} successfully created in Elastic Beanstalk."
fi

if [[ "$COMMAND" == "deploy-only" || "$COMMAND" == "all" ]]; then

    info "Updating environment in Elastic Beanstalk..."
    aws elasticbeanstalk update-environment --environment-name "${ENVIRONMENT_NAME}" --version-label "${VERSION_LABEL}"

    # check if the deployment was successful
    function check_environment() {
      aws elasticbeanstalk describe-environments --application-name "${APPLICATION_NAME}" --environment-names "${ENVIRONMENT_NAME}"
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

        if [ "${health}" == "Green" ] || [ "${health}" == "Yellow" ]; then
            info "Environment \"${ENVIRONMENT_NAME}\" is now running version \"${version}\" with status \"${status}\"."
            success "Deployment successful. URL: http://${url}"
        else
            fail "Deployment failed. Environment \"${ENVIRONMENT_NAME}\" is ${health}."
        fi
    fi

fi
