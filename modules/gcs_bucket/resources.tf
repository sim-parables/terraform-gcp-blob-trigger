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

  name                        = var.bucket_name
  storage_class               = var.storage_class
  location                    = var.storage_location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  force_destroy               = true
}