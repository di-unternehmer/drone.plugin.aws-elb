#!/usr/bin/env bats

set -e

setup() {
    # variables
    IMAGE_NAME="${DOCKERHUB_IMAGE}:${DOCKERHUB_TAG}"
    RANDOM_NUMBER=$RANDOM
    ZIP_FILE="artifact-$RANDOM_NUMBER.zip"

    APPLICATION_NAME="bbci-task-elasticbeanstalk"
    ENVIRONMENT_NAME="master"

    # clean up
    rm -f artifact-*.zip

    # create environment
    # TODO: automatize environment setup
    #aws elasticbeanstalk create-application --application-name $APPLICATION_NAME
    #aws elasticbeanstalk create-environment --application-name $APPLICATION_NAME --environment-name $ENV_NAME --solution-stack-name="64bit Amazon Linux 2018.03 v4.5.3 running Node.js"
    #aws s3api create-bucket --bucket "${APPLICATION_NAME}-${BITBUCKET_BRANCH}-deployment" --create-bucket-configuration LocationConstraint=ap-southeast-2

    # create files
    sed -i -e "s/<p>.*<\/p>/<p>$RANDOM_NUMBER<\/p>/g" test/code/index.html
    zip -j $ZIP_FILE test/code/*

}

teardown() {
    rm -f artifact-*.zip

    # TODO: automatize environment teardown
    #aws elasticbeanstalk terminate-environment --environment-name $ENV_NAME
    #aws elasticbeanstalk delete-application --application-name $APPLICATION_NAME
    #aws s3api delete-bucket --bucket "${APPLICATION_NAME}-${BITBUCKET_BRANCH}-deployment"
}


@test "artifact .zip file can be deployed to Elastic Beanstalk" {

    # Run pipe
    docker run \
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
    $IMAGE_NAME

    # Verify
    run curl --silent http://bbci-task-master.ap-southeast-2.elasticbeanstalk.com
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"$RANDOM_NUMBER"* ]]
}

@test "test invalid COMMAND fails the pipe" {

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
    $IMAGE_NAME

    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Invalid COMMAND value"* ]]
}
