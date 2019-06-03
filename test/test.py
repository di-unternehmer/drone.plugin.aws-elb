import os
import random
import shutil
import datetime

import requests

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

        with open('test/code/index.html' ,'w') as index_html:
            index_html.write(index_html_template.format(random_number=self.randon_number))

        shutil.make_archive(self.zip_file_name, 'zip', 'test/code/')


    def tearDown(self):
        os.remove(f"{self.zip_file_name}.zip")

    def test_update_successful(self):
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