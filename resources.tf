terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      configuration_aliases = [
        google.auth_session,
      ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE PROJECT DATA SOURCE
## 
## GCP Project Configurations/Details Data Source.
## ---------------------------------------------------------------------------------------------------------------------
data "google_project" "this" {
  provider = google.auth_session
}

## ---------------------------------------------------------------------------------------------------------------------
## RANDOM STRING RESOURCE
##
## This resource generates a random string of a specified length.
##
## Parameters:
## - `special`: Whether to include special characters in the random string.
## - `upper`: Whether to include uppercase letters in the random string.
## - `length`: The length of the random string.
## ---------------------------------------------------------------------------------------------------------------------
resource "random_string" "this" {
  special = false
  upper   = false
  length  = 4
}

locals {
  cloud   = "gcp"
  program = "blob-trigger"
  project = "data-flow"
}

locals {
  suffix = "${random_string.this.id}-${local.program}-${local.project}"
  gcp_cloud_function_environment = merge(var.function_environment_variables, {
    GCP_PROJECT_ID = data.google_project.this.id
  })
}

## ---------------------------------------------------------------------------------------------------------------------
## ARCHIVE FILE DATA SOURCE
## 
## Zip the latest changes to the function source code prior to deployment.
## 
## Parameters:
## - `type`: Archive file type
## - `output_file_mode`: Unix permission
## - `output_path`: Archive output path
## - `content`: Dynamic source code file paths to compressed in archive
## - `filename`: Dynamic source code file names to be mapped in compressed archive
## ---------------------------------------------------------------------------------------------------------------------
data "archive_file" "this" {
  type             = "zip"
  output_file_mode = "0666"
  output_path      = "./source/${var.function_name}.zip"

  dynamic "source" {
    for_each = var.function_contents
    content {
      content  = file(source.value.filepath) # Path to File
      filename = source.value.filename       # Name of file in zip file
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## TRIGGER BUCKET MODULE
## 
## GCS Bucket to store blobs which will trigger GCP function.
## 
## Parameters:
## - `bucket_name`: GCS bucket name
## ---------------------------------------------------------------------------------------------------------------------
module "trigger_bucket" {
  source      = "./modules/gcs_bucket"
  
  bucket_name = var.target_bucket_name

  providers = {
    google.auth_session = google.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## FUNCTION BUCKET MODULE
## 
## GCS Bucket to store GCP function source code.
## 
## Parameters:
## - `bucket_name`: GCS bucket name
## ---------------------------------------------------------------------------------------------------------------------
module "function_bucket" {
  source      = "./modules/gcs_bucket"
  
  bucket_name = var.function_bucket_name

  providers = {
    google.auth_session = google.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE STORAGE BUCKET OBJECT RESOURCE
## 
## Upload the pipeline source code to trigger on every new blob upload on the trigger bucket.
## 
## Parameters:
## - `name`: Blob name for function source code artifact
## - `bucket`: GCS Bucket name where function source code will reside
## - `source`: File path to function source code zip archive
## ---------------------------------------------------------------------------------------------------------------------
resource "google_storage_bucket_object" "this" {
  provider = google.auth_session
  
  name   = "${var.function_name}.zip"
  bucket = module.function_bucket.bucket_name
  source = data.archive_file.this.output_path
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE CLOUD FUNCTIONS FUNCTION RESOURCE
## 
## Deploy GCP Function with Blob Trigger to execute a pipeline for every new blob upload on the trigger bucket.
## No where in the GCP Function resource does it define a target blob storage to store the ETL data.
## This is configured in the GCP Function source code.
## 
## Parameters:
## - `name`: GCP Function name
## - `description`: GCP Function description defining its purpose
## - `runtime`: GCP Function runtime enviornment/ code runtime
## - `region`: GCP Function location
## - `available_member_mb`: Size of GCP Function memory to allocate
## - `source_archive_bucket`: GCS Bucket where the GCP Function source code resides
## - `source_archive_object`: Blob path to GCP Function source code artifact
## - `service_account_email`: Service Account Email to run functions as/ mirror roles
## - `timeout`: Length of time to run function before timing out
## - `entry_point`: Function to enter in source code once triggered
## - `enviornment_variables`: Mapping of ENV Variables to pass to Function runtime
## ---------------------------------------------------------------------------------------------------------------------
resource "google_cloudfunctions_function" "this" {
  provider = google.auth_session

  name        = "${var.function_name}-${local.suffix}"
  description = var.function_description
  runtime     = var.function_runtime
  region      = lower(module.trigger_bucket.bucket_location)

  available_memory_mb   = var.function_memory
  source_archive_bucket = module.function_bucket.bucket_name
  source_archive_object = google_storage_bucket_object.this.name
  service_account_email = var.function_service_account_email

  timeout               = var.function_timeout
  entry_point           = var.function_entrypoint
  environment_variables = local.gcp_cloud_function_environment

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = module.trigger_bucket.bucket_name
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE CLOUD FUNCTIONS FUNCTION IAM MEMBER RESOURCE
## 
## Provide IAM Member access to the Service Account to allow the Service Account to invoke Cloud Function Trigger when 
## new blob hits the trigger bucket.
## 
## Parameters:
## - `region`: GCP Function location
## - `cloud_function`: GCP Function name
## - `role`: IAM role name to allow cloud functions invoker to service account
## - `member`: Service account email binded to GCP Function
## ---------------------------------------------------------------------------------------------------------------------
resource "google_cloudfunctions_function_iam_member" "admin" {
  provider = google.auth_session
  
  region         = google_cloudfunctions_function.this.region
  cloud_function = google_cloudfunctions_function.this.name
  role           = "roles/cloudfunctions.admin"
  member         = var.function_service_account_member
}