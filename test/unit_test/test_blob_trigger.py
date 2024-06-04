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

References:
https://cloud.google.com/iam/docs/workforce-obtaining-short-lived-credentials#use_the_rest_api

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

from google.oauth2 import credentials, sts
from google.auth import identity_pool

import google.auth.transport.requests
import logging
import pytest
import gcsfs
import json
import uuid
import time
import os

# Environment Variables
INPUT_BUCKET=os.getenv('INPUT_BUCKET')
assert not INPUT_BUCKET is None
OUTPUT_BUCKET=os.getenv('OUTPUT_BUCKET')
assert not OUTPUT_BUCKET is None
GOOGLE_PROJECT_BILLING_NUMBER=os.getenv('GOOGLE_PROJECT_BILLING_NUMBER')
assert not GOOGLE_PROJECT_BILLING_NUMBER is None
GOOGLE_PROJECT=os.getenv('GOOGLE_PROJECT')
assert not GOOGLE_PROJECT is None

def _write_blob(fs, payload):
    with fs.open(f'gs://{INPUT_BUCKET}/test.json', 'w') as f:
        f.write(json.dumps(payload))

def _read_blob(fs):
    with fs.open(f'gs://{OUTPUT_BUCKET}/test.json', 'rb') as f:
        return json.loads(f.read())

@pytest.mark.github
@pytest.mark.access_token
def test_gcp_oauth2_blob_trigger(payload={'test_value': str(uuid.uuid4())}):
    logging.info('Pytest | Test GPC Blob Trigger')
    GOOGLE_OAUTH_ACCESS_TOKEN=os.getenv('GOOGLE_OAUTH_ACCESS_TOKEN')
    assert not GOOGLE_OAUTH_ACCESS_TOKEN is None

    creds = credentials.Credentials(token=GOOGLE_OAUTH_ACCESS_TOKEN)
    fs = gcsfs.GCSFileSystem(project=GOOGLE_PROJECT, token=creds)
    _write_blob(fs, payload)

    time.sleep(10)
    rs = _read_blob(fs)

    assert rs['test_value'] == payload['test_value']

@pytest.mark.github
@pytest.mark.wif
def test_gcp_wif_blob_trigger(payload={'test_value': str(uuid.uuid4())}):
    logging.info('Pytest | Test GPC Blob Trigger')
    GOOGLE_APPLICATION_CREDENTIALS=os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
    assert not GOOGLE_APPLICATION_CREDENTIALS is None
    scopes = [
        'https://www.googleapis.com/auth/cloud-platform',
        'https://www.googleapis.com/auth/devstorage.full_control'
    ]

    creds = identity_pool.Credentials.from_file(GOOGLE_APPLICATION_CREDENTIALS)
    creds = creds.with_scopes(scopes)
    fs = gcsfs.GCSFileSystem(project=GOOGLE_PROJECT, token=creds)
    _write_blob(fs, payload)

    time.sleep(10)
    rs = _read_blob(fs)

    assert rs['test_value'] == payload['test_value']

@pytest.mark.github
@pytest.mark.oidc
def test_gcp_oidc_blob_trigger(payload={'test_value': str(uuid.uuid4())}):
    logging.info('Pytest | Test GPC Blob Trigger')
    GOOGLE_WORKLOAD_IDENTITY_PROVIDER=os.getenv('GOOGLE_WORKLOAD_IDENTITY_PROVIDER')
    OIDC_TOKEN=os.getenv('OIDC_TOKEN')
    assert not OIDC_TOKEN is None
    assert not GOOGLE_WORKLOAD_IDENTITY_PROVIDER is None

    scopes = [
        'https://www.googleapis.com/auth/cloud-platform',
        'https://www.googleapis.com/auth/devstorage.full_control'
    ]

    try:
        client = sts.Client(token_exchange_endpoint='https://sts.googleapis.com/v1/token')
        requests = google.auth.transport.requests.Request()
        rs = client.exchange_token(
            request=requests,
            audience=GOOGLE_WORKLOAD_IDENTITY_PROVIDER,
            grant_type='urn:ietf:params:oauth:grant-type:token-exchange',
            subject_token_type='urn:ietf:params:oauth:token-type:id_token',
            subject_token=OIDC_TOKEN,
            requested_token_type='urn:ietf:params:oauth:token-type:access_token',
            scopes=scopes,
            additional_options={'userProject': GOOGLE_PROJECT_BILLING_NUMBER}
        )
        
        creds = credentials.Credentials(token=rs['access_token'])
        fs = gcsfs.GCSFileSystem(project=GOOGLE_PROJECT, token=creds)
        _write_blob(fs, payload)

        time.sleep(10)
        rs = _read_blob(fs)

        assert rs['test_value'] == payload['test_value']
    except Exception as exc:
        raise Exception('OIDC Error', rs, exc)
