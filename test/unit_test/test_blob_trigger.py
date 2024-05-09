""" Unit Test: GCP Blob Trigger

Unit testing GCP Blob Trigger involves verifying the functionality of the 
trigger mechanism responsible for initiating actions upon the creation or 
modification of objects within Google Cloud Storage (GCS) buckets. This 
entails simulating the triggering event, such as the addition of a new 
blob to a specified bucket, and validating that the associated actions, 
like invoking cloud functions or workflows, are executed as expected. Through 
meticulous testing, developers ensure the reliability and accuracy of their 
GCP Blob Trigger implementation, fostering robustness and confidence in their 
cloud-based applications.

Local Testing Steps:
```
terraform init && \
terraform apply -auto-approve

export INPUT_BUCKET=$(terraform output -raw trigger_bucket_name)
export OUTPUT_BUCKET=$(terraform output -raw results_bucket_name)
export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)

python3 -m pytest -m github

terraform destroy -auto-approve
```
"""

from google.oauth2 import credentials

import logging
import pytest
import gcsfs
import json
import uuid
import time
import os

# Environment Variables
GOOGLE_OAUTH_ACCESS_TOKEN=os.getenv('GOOGLE_OAUTH_ACCESS_TOKEN')
INPUT_BUCKET=os.getenv('INPUT_BUCKET')
OUTPUT_BUCKET=os.getenv('OUTPUT_BUCKET')
GOOGLE_PROJECT=os.getenv('GOOGLE_PROJECT')

def _write_blob(fs, payload):
    with fs.open(f'gs://{INPUT_BUCKET}/test.json', 'w') as f:
        f.write(json.dumps(payload))

def _read_blob(fs):
    with fs.open(f'gs://{OUTPUT_BUCKET}/test.json', 'rb') as f:
        return json.loads(f.read())

@pytest.mark.github
def test_gcp_blob_trigger(payload={'test_value': str(uuid.uuid4())}):
    logging.info('Pytest | Test GPC Blob Trigger')

    creds = credentials.Credentials(token=GOOGLE_OAUTH_ACCESS_TOKEN)
    fs = gcsfs.GCSFileSystem(project=GOOGLE_PROJECT, token=creds)
    _write_blob(fs, payload)

    time.sleep(10)
    rs = _read_blob(fs)

    assert rs['test_value'] == payload['test_value']
