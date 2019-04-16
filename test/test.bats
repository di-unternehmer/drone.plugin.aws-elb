#!/usr/bin/env bats

set -e

setup() {
    # variables
    IMAGE_NAME="${DOCKERHUB_IMAGE}:${DOCKERHUB_TAG}"

    APPLICATION_NAME="bbci-task-elasticbeanstalk"
    ENVIRONMENT_NAME="master"

    # create environment
    # TODO: automatize environment setup
    #aws elasticbeanstalk create-application --application-name $APPLICATION_NAME
    #aws elasticbeanstalk create-environment --application-name $APPLICATION_NAME --environment-name $ENV_NAME --solution-stack-name="64bit Amazon Linux 2018.03 v4.5.3 running Node.js"
    #aws s3api create-bucket --bucket "${APPLICATION_NAME}-${BITBUCKET_BRANCH}-deployment" --create-bucket-configuration LocationConstraint=ap-southeast-2
}

teardown() {
    rm -f artifact-*.*
    git checkout test/code/index.html 

    # TODO: automatize environment teardown
    #aws elasticbeanstalk terminate-environment --environment-name $ENV_NAME
    #aws elasticbeanstalk delete-application --application-name $APPLICATION_NAME
    #aws s3api delete-bucket --bucket "${APPLICATION_NAME}-${BITBUCKET_BRANCH}-deployment"
}


setup_files() {
    RANDOM_NUMBER=$RANDOM
    ZIP_FILE_NAME="artifact-$RANDOM_NUMBER"

    # clean up
    rm -f artifact-*.*

    # create files
    sed -i -e "s/<p>.*<\/p>/<p>$RANDOM_NUMBER<\/p>/g" test/code/index.html
}


@test "artifact .zip file can be deployed to Elastic Beanstalk" {
    setup_files
    ZIP_FILE="${ZIP_FILE_NAME}.zip"

    zip -j "${ZIP_FILE_NAME}.zip" test/code/*

    # Run pipe
    run docker run \
      -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
      -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
      -e AWS_DEFAULT_REGION="ap-southeast-2" \
      -e APPLICATION_NAME="$APPLICATION_NAME" \
      -e ENVIRONMENT_NAME="$ENVIRONMENT_NAME" \
      -e S3_BUCKET="${APPLICATION_NAME}-master-deployment" \
      -e VERSION_LABEL="${APPLICATION_NAME}-$(date -u "+%Y-%m-%d_%H%M%S")" \
      -e ZIP_FILE="$ZIP_FILE" \
      -e WAIT="true" \
      -e WAIT_INTERVAL=10 \
      -v $(pwd):$(pwd) \
      -w $(pwd) \
    ${IMAGE_NAME}

    # Verify
    run curl --silent http://bbci-task-master.ap-southeast-2.elasticbeanstalk.com
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"$RANDOM_NUMBER"* ]]
}

@test "artifact .jar file can be deployed to Elastic Beanstalk" {
    setup_files
    ZIP_FILE="${ZIP_FILE_NAME}.jar"

    cd test/code
    jar -cf "${ZIP_FILE_NAME}.jar" *
    mv "${ZIP_FILE_NAME}".* ../..
    cd ../..

    # Run pipe
    run docker run \
      -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
      -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
      -e AWS_DEFAULT_REGION="ap-southeast-2" \
      -e APPLICATION_NAME="$APPLICATION_NAME" \
      -e ENVIRONMENT_NAME="$ENVIRONMENT_NAME" \
      -e S3_BUCKET="${APPLICATION_NAME}-master-deployment" \
      -e VERSION_LABEL="${APPLICATION_NAME}-$(date -u "+%Y-%m-%d_%H%M%S")" \
      -e ZIP_FILE="$ZIP_FILE" \
      -e WAIT="true" \
      -e WAIT_INTERVAL=10 \
      -v $(pwd):$(pwd) \
      -w $(pwd) \
    ${IMAGE_NAME}

    # Verify
    run curl --silent http://bbci-task-master.ap-southeast-2.elasticbeanstalk.com
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"$RANDOM_NUMBER"* ]]
}

@test "artifact .war file can be deployed to Elastic Beanstalk" {
    setup_files
    ZIP_FILE="${ZIP_FILE_NAME}.war"

    cd test/code
    jar -cf "${ZIP_FILE_NAME}.war" *
    mv "${ZIP_FILE_NAME}".* ../..
    cd ../..

    # Run pipe
    run docker run \
      -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
      -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
      -e AWS_DEFAULT_REGION="ap-southeast-2" \
      -e APPLICATION_NAME="$APPLICATION_NAME" \
      -e ENVIRONMENT_NAME="$ENVIRONMENT_NAME" \
      -e S3_BUCKET="${APPLICATION_NAME}-master-deployment" \
      -e VERSION_LABEL="${APPLICATION_NAME}-$(date -u "+%Y-%m-%d_%H%M%S")" \
      -e ZIP_FILE="$ZIP_FILE" \
      -e WAIT="true" \
      -e WAIT_INTERVAL=10 \
      -v $(pwd):$(pwd) \
      -w $(pwd) \
    ${IMAGE_NAME}

    # Verify
    run curl --silent http://bbci-task-master.ap-southeast-2.elasticbeanstalk.com
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"$RANDOM_NUMBER"* ]]
}

@test "test invalid COMMAND fails the pipe" {
    setup_files
    ZIP_FILE="${ZIP_FILE_NAME}.zip"

    # Run pipe
    run docker run \
      -e COMMAND="only-deploy" \
      -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
      -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
      -e AWS_DEFAULT_REGION="ap-southeast-2" \
      -e APPLICATION_NAME="$APPLICATION_NAME" \
      -e ENVIRONMENT_NAME="$ENVIRONMENT_NAME" \
      -e S3_BUCKET="${APPLICATION_NAME}-master-deployment" \
      -e VERSION_LABEL="${APPLICATION_NAME}-$(date -u "+%Y-%m-%d_%H%M%S")" \
      -e ZIP_FILE="$ZIP_FILE" \
      -e WAIT="true" \
      -e WAIT_INTERVAL=10 \
      -v $(pwd):$(pwd) \
      -w $(pwd) \
    ${IMAGE_NAME}

    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Invalid COMMAND value"* ]]
}
