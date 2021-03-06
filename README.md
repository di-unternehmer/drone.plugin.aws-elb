# Drone.io Step for AWS Elastic Beanstalk 
This is based on Atlassians Bitbucket Pipelines Pipe for AWS Elastic Beanstalk.
For more details see: https://bitbucket.org/atlassian/aws-elasticbeanstalk-deploy/src/master/

Deploy your code using [AWS Elastic Beanstalk](https://aws.amazon.com/elasticbeanstalk/). 

## YAML Definition

Add the following snippet to the step section of your `.drone.yml` file:
    
```yaml
steps:
- name: 'Deploy to Elastic Beanstalk'
  image: kapale/drone-deploy-to-aws-eb
  pull: always
  settings:
    AWS_ACCESS_KEY_ID:
      from_secret: aws_access_key_id
    AWS_SECRET_ACCESS_KEY:
      from_secret: 
    AWS_DEFAULT_REGION: 'eu-central-1'
    APPLICATION_NAME: '<string>'
    ENVIRONMENT_NAME: '<string>'
    ZIP_FILE: '<string>'
    # S3_BUCKET: '<string>' # Optional.
    # VERSION_LABEL: '<string>' # Optional.
    # DESCRIPTION: '<string>' # Optional.
    # WAIT: '<boolean>' # Optional.
    # WAIT_INTERVAL: '<integer>' # Optional.
    # COMMAND: '<string>' # Optional.
    # DEBUG: '<boolean>' # Optional.
  when:
    event: tag
    branch: master
```

## Variables

### Basic usage

| Variable                     | Usage                                                |
| ------------------------------- | ---------------------------------------------------- |
| AWS_ACCESS_KEY_ID (*)           |  AWS access key. |
| AWS_SECRET_ACCESS_KEY (*)       |  AWS secret key. |
| AWS_DEFAULT_REGION (*)          |  The AWS region code (us-east-1, us-west-2, etc.) of the region containing the AWS resource(s). For more information, see [Regions and Endpoints][Regions and Endpoints] in the _Amazon Web Services General Reference_. |
| APPLICATION_NAME (*)            |  The name of the Elastic Beanstalk application. |
| ENVIRONMENT_NAME (*)            |  Environment name. |
| ZIP_FILE (*)                    |  The application source bundle to deploy (zip, jar, war). |
| S3_BUCKET                       |  Bucket name used by Elastic Beanstalk to store artifacts. Default: `${APPLICATION_NAME}-elasticbeanstalk-deployment`. |
| VERSION_LABEL                   |  Version label for the new application revision. Default: `${APPLICATION_NAME}-${DRONE_BUILD_NUMBER}-${DRONE_COMMIT:0:8}`. |
| DESCRIPTION                     |  Description for the new application revision. Default: a URL pointing to the pipeline result page. |
| WAIT                            |  Wait for deployment to complete. Default: `false`. |
| WAIT_INTERVAL                   |  Time to wait between polling for deployment to complete (in seconds). Default: `10`. |
| COMMAND                         |  Command to be executed during the deployment. Valid options are `all`, `upload-only`, `deploy-only`. Default: `all`. |
| DEBUG                           |  Turn on extra debug information. Default: `false`. |
_(*) = required variable._


### Advanced usage

If `COMMAND` is set to `upload-only`

| Variable                     | Usage                                                |
| ------------------------------- | ---------------------------------------------------- |
| AWS_ACCESS_KEY_ID (*)           |  AWS access key. |
| AWS_SECRET_ACCESS_KEY (*)       |  AWS secret key. |
| AWS_DEFAULT_REGION (*)          |  The AWS region code (us-east-1, us-west-2, etc.) of the region containing the AWS resource(s). For more information, see [Regions and Endpoints][Regions and Endpoints] in the _Amazon Web Services General Reference_. |
| APPLICATION_NAME (*)            |  The name of the Elastic Beanstalk application. |
| COMMAND (*)                     |  Command to be used. Use `upload-only` here. |
| ZIP_FILE (*)                    |  The application source bundle to deploy (zip, jar, war). |
| S3_BUCKET                       |  Bucket name used by Elastic Beanstalk to store artifacts. Default: `${APPLICATION_NAME}-elasticbeanstalk-deployment}`. |
| VERSION_LABEL                   |  Version label for the new application revision. Default: `${ENVIRONMENT_NAME}_${DRONE_COMMIT:0:8}_YYYY-mm-dd_HHMMSS)`. |
| DESCRIPTION                     |  Description for the new application revision. Default: "". |
| DEBUG                           |  Turn on extra debug information. Default: `false`. |

If `COMMAND` is set to `deploy-only`

| Variable                     | Usage                                                |
| ------------------------------- | ---------------------------------------------------- |
| AWS_ACCESS_KEY_ID (*)           |  AWS access key. |
| AWS_SECRET_ACCESS_KEY (*)       |  AWS secret key. |
| AWS_DEFAULT_REGION (*)          |  The AWS region code (us-east-1, us-west-2, etc.) of the region containing the AWS resource(s). For more information, see [Regions and Endpoints][Regions and Endpoints] in the _Amazon Web Services General Reference_. |
| APPLICATION_NAME (*)            |  The name of the Elastic Beanstalk application. |
| COMMAND (*)                     |  Command to be used. Use `deploy-only` here. |
| ENVIRONMENT_NAME (*)            |  Environment name. |
| VERSION_LABEL                   |  Version label for the new application revision. Default: `${ENVIRONMENT_NAME}_${DRONE_COMMIT:0:8}_YYYY-mm-dd_HHMMSS)`. |
| WAIT                            |  Wait for deployment to complete. Default: `false`. |
| WAIT_INTERVAL                   |  Time to wait between polling for deployment to complete (in seconds). Default: `10`. |
| DEBUG                           |  Turn on extra debug information. Default: `false`. |


## Details

This pipe deploys a new version of an application to an Elastic Beanstalk environment associated with the application.

With Elastic Beanstalk, you can quickly deploy and manage applications in the AWS Cloud without worrying about the infrastructure that runs those applications. Elastic Beanstalk reduces management complexity without restricting choice or control. You simply upload your application, and Elastic Beanstalk automatically handles the details of capacity provisioning, load balancing, scaling, and application health monitoring.

For advanced use cases and best practices, we recommend _build once and deploy many_ approach. So, if you have multiple environments we recommend using the `COMMAND` variable to separate your CI/CD workflow into different operations / pipes:

- `COMMAND: 'upload-only'`: It will upload the artifact and release a version in Elastic Beanstalk.
- `COMMAND: 'deploy-only'`: It will deploy the specified version to the desired environment(s). 


## Prerequisites
* An IAM user is configured with sufficient permissions to perform a deployment to your application and upload artifacts to the S3 bucket.
* You have configured the Elastic Beanstalk application and environment.
* An S3 bucket has been set up to which deployment artifacts will be copied. Use name `${APPLICATION_NAME}-elasticbeanstalk-deployment` to automatically use it.

## Examples 

### Basic example:

Upload the artifact `application.zip` and deploy your environment.
    
```yaml
script:
  - pipe: atlassian/aws-elasticbeanstalk-deploy:0.6.0
    variables:
      AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
      AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
      AWS_DEFAULT_REGION: 'us-east-1'
      APPLICATION_NAME: 'my-app-name'
      ENVIRONMENT_NAME: 'production'
      ZIP_FILE: 'application.zip'
```

### Advanced example:
    
Upload the artifact `application.zip` and create a version `deploy-$DRONE_BUILD_NUMBER-multiple` in Elastic Beanstalk.

```yaml
- pipe: atlassian/aws-elasticbeanstalk-deploy:0.6.0
  variables:
    AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
    AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION
    APPLICATION_NAME: 'application-test'
    COMMAND: 'upload-only'
    ZIP_FILE: 'application.zip'
    S3_BUCKET: 'application-test-bucket'
    VERSION_LABEL: 'deploy-$DRONE_BUILD_NUMBER-multiple'
```

Deploy your version `deploy-$DRONE_BUILD_NUMBER-multiple` into the environment `production` and wait until the deployment is completed to see the status.

```yaml
- pipe: atlassian/aws-elasticbeanstalk-deploy:0.6.0
  variables:
    AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
    AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION
    APPLICATION_NAME: 'application-test'
    COMMAND: 'deploy-only'
    VERSION_LABEL: 'deploy-$DRONE_BUILD_NUMBER-multiple'
    ENVIRONMENT_NAME: 'production'
    WAIT: 'true'
```

Deploy multicontainer Docker environment as an AWS Elastic Beanstalk application to AWS Cloud and wait until the deployment is completed to see the status.
You can find the complete source code for the sample multicontainer app by following this link [example-aws-elasticbeanstalk-deploy-docker-multicontainer repository](https://bitbucket.org/bitbucketpipelines/example-aws-elasticbeanstalk-deploy-docker-multicontainer/src/master).

```yaml
- step:
    name: Build docker-multicontainer-v2 App
    script:
    - zip -r docker-multicontainer-v2.zip cron.yaml Dockerrun.aws.json .ebextensions php-app proxy
    artifacts:
    - docker-multicontainer-v2.zip
- step:
    name: Deploy to AWS EBS
    caches:
      - pip
    script:
    - pipe: atlassian/aws-elasticbeanstalk-deploy:0.6.0
      variables:
        AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
        AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
        AWS_DEFAULT_REGION: 'us-east-1'
        APPLICATION_NAME: 'test-ebs-multi-docker'
        ENVIRONMENT_NAME: 'TestEbsMultiDocker-env'
        ZIP_FILE: 'docker-multicontainer-v2.zip'
        WAIT: 'true'
```


## Support
If you'd like help with this pipe, or you have an issue or feature request, [let us know on Community][community].

If you're reporting an issue, please include:

* the version of the pipe
* relevant logs and error messages
* steps to reproduce


## License
Copyright (c) 2018 Atlassian and others.
Apache 2.0 licensed, see [LICENSE.txt](LICENSE.txt) file.

[community]: https://community.atlassian.com/t5/forums/postpage/choose-node/true/interaction-style/qanda?add-tags=bitbucket-pipelines,pipes,aws
[Regions and Endpoints]: https://docs.aws.amazon.com/general/latest/gr/rande.html
