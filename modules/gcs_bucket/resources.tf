terraform{
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
}

##----------------------------------------------------------------------------------------------------------------------
## GOOGLE STORAGE BUCKET
## 
## Google Cloud Storage Bucket creation.
## 
## Parameters:
## - `name`: GCS bucket name
## - `storage_class`: GCS Blob storage type
## - `location`: GCS region
## - `uniform_bucket_level_access`: Flag to uniformly control access to your Cloud Storage resources
## ---------------------------------------------------------------------------------------------------------------------
resource "google_storage_bucket" "this" {
  provider                    = google.auth_session

  name                        = "${var.bucket_name}-${local.suffix}"
  storage_class               = var.storage_class
  location                    = var.storage_location
  uniform_bucket_level_access = true
  force_destroy               = true
}