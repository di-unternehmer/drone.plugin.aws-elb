import os
import random
import shutil
import datetime
import subprocess

import requests
import boto3

from bitbucket_pipes_toolkit.test import PipeTestCase

index_html_template = """
<html>
  <head>
    <title>Bitbucket Pipelines</title>
  </head>
  <body>
      <p>{random_number}</p>
  </body>
</html>
"""

def isoformat_now():
    return datetime.datetime.now().isoformat()

class ECSDeployTestCase(PipeTestCase):

    def setUp(self):
        super().setUp()
        self.image_name=f"{os.getenv('DOCKERHUB_IMAGE')}:{os.getenv('DOCKERHUB_TAG')}"
        self.application_name="bbci-task-elasticbeanstalk"
        self.environment_name="master"

        self.randon_number=random.randint(0, 32767)
        self.zip_file_name=f"artifact-{self.randon_number}"

        with open('test/code/index.html' ,'w+') as index_html:
            index_html.write(index_html_template.format(random_number=self.randon_number))

        shutil.make_archive(self.zip_file_name, 'zip', 'test/code/')


    def tearDown(self):
        os.remove(os.path.join(os.getcwd(), f"{self.zip_file_name}.zip"))

    def test_artifact_can_be_deployed(self):
        "artifact .zip file can be deployed to Elastic Beanstalk"

        service_name = os.getenv('ECS_SERVICE_NAME')
        result = self.run_container(environment={
            'AWS_SECRET_ACCESS_KEY': os.getenv('AWS_SECRET_ACCESS_KEY'),
            'AWS_ACCESS_KEY_ID': os.getenv('AWS_ACCESS_KEY_ID'),
            'AWS_DEFAULT_REGION': os.getenv('AWS_DEFAULT_REGION', 'us-east-1'),
            'ENVIRONMENT_NAME': os.getenv('ENVIRONMENT_NAME'),
            'APPLICATION_NAME': os.getenv('APPLICATION_NAME'),
            'S3_BUCKET': f"{os.getenv('APPLICATION_NAME')}-master-deployment",
            'VERSION_LABEL': f"{os.getenv('APPLICATION_NAME')}-{isoformat_now()}",
            'ZIP_FILE': os.path.join(os.getcwd(), f"{self.zip_file_name}.zip"),
            'WAIT': 'true',
            'WAIT_INTERVAL': 10
        })

        self.assertIn('Deployment successful', result)

        response = requests.get('http://bbci-task-master.ap-southeast-2.elasticbeanstalk.com')

        self.assertIn(str(self.randon_number), response.text)

    def test_default_description_should_have_url(self):
        "artifact .zip file can be deployed to Elastic Beanstalk"
        application_name = os.getenv('APPLICATION_NAME')
        version_label = f"{application_name}-{isoformat_now()}"
        repo_owner = os.getenv('BITBUCKET_REPO_OWNER')

        service_name = os.getenv('ECS_SERVICE_NAME')
        result = self.run_container(environment={
            'AWS_SECRET_ACCESS_KEY': os.getenv('AWS_SECRET_ACCESS_KEY'),
            'COMMAND': 'upload-only',
            'AWS_ACCESS_KEY_ID': os.getenv('AWS_ACCESS_KEY_ID'),
            'AWS_DEFAULT_REGION': os.getenv('AWS_DEFAULT_REGION', 'us-east-1'),
            'ENVIRONMENT_NAME': os.getenv('ENVIRONMENT_NAME'),
            'APPLICATION_NAME': application_name,
            'S3_BUCKET': f"{application_name}-master-deployment",
            'VERSION_LABEL': version_label,
            'ZIP_FILE': os.path.join(os.getcwd(), f"{self.zip_file_name}.zip"),
            'WAIT': 'true',
            'WAIT_INTERVAL': 10,
            'BITBUCKET_REPO_OWNER': 'atlassian',
            'BITBUCKET_BUILD_NUMBER': os.getenv('BITBUCKET_BUILD_NUMBER'),
            'BITBUCKET_REPO_SLUG': os.getenv('BITBUCKET_REPO_SLUG')
        })

        client = boto3.client('elasticbeanstalk', region_name=os.getenv('AWS_DEFAULT_REGION'))

        application_version = client.describe_application_versions(ApplicationName=application_name)['ApplicationVersions'][0]
        url = f"https://bitbucket.org/{repo_owner}/{os.getenv('BITBUCKET_REPO_SLUG')}/addon/pipelines/home#!/results/{os.getenv('BITBUCKET_BUILD_NUMBER')}"
        self.assertIn(url, application_version['Description'])

    def test_artifact_jar_can_be_deployed(self):
        "artifact .jar file can be deployed to Elastic Beanstalk"

        jar_file_name=f"{self.zip_file_name}.jar"

        os.chdir('test/code')
        os.system(f"jar -cf {jar_file_name} *")
        shutil.move(jar_file_name, '../..')
        os.chdir('../..')

        service_name = os.getenv('ECS_SERVICE_NAME')
        result = self.run_container(environment={
            'AWS_SECRET_ACCESS_KEY': os.getenv('AWS_SECRET_ACCESS_KEY'),
            'AWS_ACCESS_KEY_ID': os.getenv('AWS_ACCESS_KEY_ID'),
            'AWS_DEFAULT_REGION': os.getenv('AWS_DEFAULT_REGION', 'us-east-1'),
            'ENVIRONMENT_NAME': os.getenv('ENVIRONMENT_NAME'),
            'APPLICATION_NAME': os.getenv('APPLICATION_NAME'),
            'S3_BUCKET': f"{os.getenv('APPLICATION_NAME')}-master-deployment",
            'VERSION_LABEL': f"{os.getenv('APPLICATION_NAME')}-{isoformat_now()}",
            'ZIP_FILE': os.path.join(os.getcwd(), f"{self.zip_file_name}.jar"),
            'WAIT': 'true',
            'WAIT_INTERVAL': 10
        })

        self.assertIn('Deployment successful', result)

        response = requests.get('http://bbci-task-master.ap-southeast-2.elasticbeanstalk.com')

        self.assertIn(str(self.randon_number), response.text)


    def test_artifact_war_can_be_deployed(self):
        "artifact .war file can be deployed to Elastic Beanstalk"

        jar_file_name=f"{self.zip_file_name}.war"

        os.chdir('test/code')
        os.system(f"jar -cf {jar_file_name} *")
        shutil.move(jar_file_name, '../..')
        os.chdir('../..')

        service_name = os.getenv('ECS_SERVICE_NAME')
        result = self.run_container(environment={
            'AWS_SECRET_ACCESS_KEY': os.getenv('AWS_SECRET_ACCESS_KEY'),
            'AWS_ACCESS_KEY_ID': os.getenv('AWS_ACCESS_KEY_ID'),
            'AWS_DEFAULT_REGION': os.getenv('AWS_DEFAULT_REGION', 'us-east-1'),
            'ENVIRONMENT_NAME': os.getenv('ENVIRONMENT_NAME'),
            'APPLICATION_NAME': os.getenv('APPLICATION_NAME'),
            'S3_BUCKET': f"{os.getenv('APPLICATION_NAME')}-master-deployment",
            'VERSION_LABEL': f"{os.getenv('APPLICATION_NAME')}-{isoformat_now()}",
            'ZIP_FILE': os.path.join(os.getcwd(), f"{self.zip_file_name}.war"),
            'WAIT': 'true',
            'WAIT_INTERVAL': 10
        })

        self.assertIn('Deployment successful', result)

        response = requests.get('http://bbci-task-master.ap-southeast-2.elasticbeanstalk.com')

        self.assertIn(str(self.randon_number), response.text)

    def test_artifact_no_extension_can_be_deployed(self):
        "artifact file without an extension can be deployed to Elastic Beanstalk"

        file_name=f"{self.zip_file_name}"

        os.chdir('test/code')
        os.system(f"jar -cf {file_name} *")
        shutil.move(file_name, '../..')
        os.chdir('../..')

        service_name = os.getenv('ECS_SERVICE_NAME')
        result = self.run_container(environment={
            'AWS_SECRET_ACCESS_KEY': os.getenv('AWS_SECRET_ACCESS_KEY'),
            'AWS_ACCESS_KEY_ID': os.getenv('AWS_ACCESS_KEY_ID'),
            'AWS_DEFAULT_REGION': os.getenv('AWS_DEFAULT_REGION', 'us-east-1'),
            'ENVIRONMENT_NAME': os.getenv('ENVIRONMENT_NAME'),
            'APPLICATION_NAME': os.getenv('APPLICATION_NAME'),
            'S3_BUCKET': f"{os.getenv('APPLICATION_NAME')}-master-deployment",
            'VERSION_LABEL': f"{os.getenv('APPLICATION_NAME')}-{isoformat_now()}",
            'ZIP_FILE': os.path.join(os.getcwd(), f"{self.zip_file_name}"),
            'WAIT': 'true',
            'WAIT_INTERVAL': 10
        })

        self.assertIn('Deployment successful', result)

        response = requests.get('http://bbci-task-master.ap-southeast-2.elasticbeanstalk.com')

        self.assertIn(str(self.randon_number), response.text)

    def test_artifact_custom_extension_can_be_deployed(self):
        "artifact file with custom extension can be deployed to Elastic Beanstalk"

        file_name=f"{self.zip_file_name}.custom"

        os.chdir('test/code')
        os.system(f"jar -cf {file_name} *")
        shutil.move(file_name, '../..')
        os.chdir('../..')

        service_name = os.getenv('ECS_SERVICE_NAME')
        result = self.run_container(environment={
            'AWS_SECRET_ACCESS_KEY': os.getenv('AWS_SECRET_ACCESS_KEY'),
            'AWS_ACCESS_KEY_ID': os.getenv('AWS_ACCESS_KEY_ID'),
            'AWS_DEFAULT_REGION': os.getenv('AWS_DEFAULT_REGION', 'us-east-1'),
            'ENVIRONMENT_NAME': os.getenv('ENVIRONMENT_NAME'),
            'APPLICATION_NAME': os.getenv('APPLICATION_NAME'),
            'S3_BUCKET': f"{os.getenv('APPLICATION_NAME')}-master-deployment",
            'VERSION_LABEL': f"{os.getenv('APPLICATION_NAME')}-{isoformat_now()}",
            'ZIP_FILE': os.path.join(os.getcwd(), f"{self.zip_file_name}.custom"),
            'WAIT': 'true',
            'WAIT_INTERVAL': 10
        })

        self.assertIn('Deployment successful', result)

        response = requests.get('http://bbci-task-master.ap-southeast-2.elasticbeanstalk.com')

        self.assertIn(str(self.randon_number), response.text)

    def test_pipe_should_fail_when_invalid_command(self):
        "test invalid COMMAND fails the pipe"

        service_name = os.getenv('ECS_SERVICE_NAME')
        result = self.run_container(environment={
            'COMMAND': "only-deploy",
            'AWS_SECRET_ACCESS_KEY': os.getenv('AWS_SECRET_ACCESS_KEY'),
            'AWS_ACCESS_KEY_ID': os.getenv('AWS_ACCESS_KEY_ID'),
            'AWS_DEFAULT_REGION': os.getenv('AWS_DEFAULT_REGION', 'us-east-1'),
            'ENVIRONMENT_NAME': os.getenv('ENVIRONMENT_NAME'),
            'APPLICATION_NAME': os.getenv('APPLICATION_NAME'),
            'S3_BUCKET': f"{os.getenv('APPLICATION_NAME')}-master-deployment",
            'VERSION_LABEL': f"{os.getenv('APPLICATION_NAME')}-{isoformat_now()}",
            'ZIP_FILE': os.path.join(os.getcwd(), f"{self.zip_file_name}.zip"),
            'WAIT': 'true',
            'WAIT_INTERVAL': 10
        })

        self.assertIn('Invalid COMMAND value', result)
