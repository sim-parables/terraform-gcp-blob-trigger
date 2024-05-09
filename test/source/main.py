""" GCP Cloud Function Example

A Google Cloud Platform (GCP) Cloud Function with a Blob Storage Trigger is a 
serverless function that automatically executes in response to changes in a 
specified Cloud Storage bucket. When a new blob (file) is created, modified, 
or deleted in the specified bucket, the Cloud Function is triggered, allowing 
you to perform custom logic or processing on the blob data. This trigger mechanism 
enables event-driven architecture and allows you to build scalable and event-based 
solutions on GCP.

This example in particular will take JSON data from the Trigger GCS Bucket,
and store the exact same content with same file name in the Results GCS Bucket
referred to under ENV Variable OUTPUT_BUCKET.

"""

import functions_framework
import logging
import gcsfs
import json
import sys
import os

# Environment Variables
OUTPUT_BUCKET=os.getenv('OUTPUT_BUCKET')
GOOGLE_PROJECT=os.getenv('GOOGLE_PROJECT')
GCP_TOKEN=os.getenv('GCP_TOKEN', 'cloud')

# Setup
logging.basicConfig(stream=sys.stdout, level=logging.INFO)

def load_json(fs, bucket, name):
    """
    Load JSON data from a file.

    Args:
        fs (gcsfs.GCSFileSystem): File system object.
        bucket (str): Name of the bucket.
        name (str): Name of the JSON file.

    Returns:
        dict: Loaded JSON data.

    """
    file_path = os.path.join(bucket, name)
    logging.info('Loading JSON %s' % file_path)

    with fs.open(os.path.join(bucket, name), 'rb') as f:
        return json.load(f)

# Triggered by a change in a storage bucket
@functions_framework.cloud_event
def run(cloud_event):
    """
    Function triggered by a Cloud Storage event.

    Args:
        cloud_event (CloudEvent): The CloudEvent object containing information about the event.

    """
    logging.info('Bucket:%s Blob:%s | Initiating ETL trigger' % (
        cloud_event.data['bucket'], cloud_event.data['name']
    ))

    fs = gcsfs.GCSFileSystem(project=GOOGLE_PROJECT, token=GCP_TOKEN)
    rs = load_json(fs, cloud_event.data['bucket'], cloud_event.data['name'])
    with fs.open(os.path.join(f'gs://{OUTPUT_BUCKET}', cloud_event.data['name']), 'w') as f:
        f.write(json.dumps(rs))
