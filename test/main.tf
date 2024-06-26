terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }

  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "sim-parables"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "ci-cd-gcp-workspace"
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE PROJECT DATA SOURCE
## 
## GCP Project Configurations/Details Data Source.
## ---------------------------------------------------------------------------------------------------------------------
data "google_project" "this" {
  provider = google.tokengen
}

locals {
  principal_roles = [
    {
      principal = "principal://iam.googleapis.com/projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${var.POOL_ID}/subject/repo:${var.GITHUB_REPOSITORY}:ref:${var.GITHUB_REF}",
      role      = "roles/iam.workloadIdentityUser"
    },
    {
      principal = "principal://iam.googleapis.com/projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${var.POOL_ID}/subject/repo:${var.GITHUB_REPOSITORY}:environment:${var.GITHUB_ENV}",
      role      = "roles/iam.workloadIdentityUser"
    },
  ]
}


## ---------------------------------------------------------------------------------------------------------------------
## GCP PROVIDER
##
## Configures the GCP provider with OIDC Connect via ENV Variables.
## ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  alias = "tokengen"
}

##---------------------------------------------------------------------------------------------------------------------
## GCP SERVICE ACCOUNT MODULE
##
## This module provisions a GCP service account along with associated roles and security groups.
##
## Parameters:
## - `IMPERSONATE_SERVICE_ACCOUNT_EMAIL`: Existing GCP service account email to impersonate for new SA creation.
## - `new_service_account_name`: New service account name.
##
## Providers:
## - `google.tokengen`: Alias for the GCP provider for generating service accounts.
##---------------------------------------------------------------------------------------------------------------------
module "service_account_auth" {
  source = "github.com/sim-parables/terraform-gcp-service-account.git?ref=5645d79241069640d425010dbf0cf11785a03da7"

  IMPERSONATE_SERVICE_ACCOUNT_EMAIL = var.IMPERSONATE_SERVICE_ACCOUNT_EMAIL
  new_service_account_name          = "example-tf-sa"
  roles_list = [
    "roles/storage.admin",
    "roles/cloudfunctions.admin",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountAdmin"
  ]

  providers = {
    google.tokengen = google.tokengen
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## GCP PROVIDER
##
## Authenticated session with newly created service account.
##
## Parameters:
## - `access_token`: Access token from service_account_auth module
## ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  alias        = "auth_session"
  access_token = module.service_account_auth.access_token
  project      = data.google_project.this.project_id
}

##---------------------------------------------------------------------------------------------------------------------
## GCP WORKLOAD IDENTITY FEDERTAION PRINICPALS MODULE
##
## This module creates Service Account grants to a specific Google Workload Identity Federation (WIF) Pool
## to allow OpenID Connect authorization within Github Actions.
##
## Parameters:
## - `project_number`: GCP project number (not ID).
## - `pool_id`: Exiting Google WIF pool ID.
## - `prinicpal_roles`: List of objects defining WIF prinicpals and impersonating roles.
## - `service_account_id`: New service account ID.
##
## Providers:
## - `google.tokengen`: Alias for the GCP provider for generating service accounts.
##---------------------------------------------------------------------------------------------------------------------
module "workload_identity_federation_principals" {
  source = "github.com/sim-parables/terraform-gcp-service-account.git?ref=5645d79241069640d425010dbf0cf11785a03da7//modules/workflow_identity_federation_principal"

  project_number     = data.google_project.this.number
  pool_id            = var.POOL_ID
  provider_id        = var.PROVIDER_ID
  principal_roles    = local.principal_roles
  service_account_id = module.service_account_auth.service_account_id

  providers = {
    google.auth_session = google.auth_session
  }
}

##---------------------------------------------------------------------------------------------------------------------
## GCP RESULTS BUCKET MODULE
##
## This module provisions a GCS bucket which will act as the store for results created by GCP Cloud Function.
##
## Parameters:
## - `bucket_name`: GCS bucket name for Cloud Function results
##
## Providers:
## - `google.tokengen`: Alias for the GCP provider for generating service accounts.
##---------------------------------------------------------------------------------------------------------------------
module "gcp_results_bucket" {
  source      = "../modules/gcs_bucket"
  depends_on  = [module.service_account_auth]
  bucket_name = "example-results-bucket"

  providers = {
    google.auth_session = google.auth_session
  }
}


##---------------------------------------------------------------------------------------------------------------------
## GCP CLOUD FUNCTION MODULE
##
## This module provisions a GCP Cloud Function with Blob Trigger capabilities to run stored procedure on newly created
## blobs landing in the trigger bucket.
##
## Parameters:
## - `function_name`: GCP Cloud Function name
## - `function_service_account_email`: Recently providioned service account email
## - `function_service_account_member`: Recently providioned service account member ID
## - `function_entrypoint`: Function name to run from source code on blob trigger
## - `target_bucket_name`: GCS Bucket to create and configure the Cloud Function to trigger on
## - `function_contents`: Dynamic mapping of Function source code files to archive
##
## Providers:
## - `google.tokengen`: Alias for the GCP provider for generating service accounts.
##---------------------------------------------------------------------------------------------------------------------
module "gcp_cloud_function" {
  source                          = "../"
  depends_on                      = [module.service_account_auth]
  function_name                   = "example-cloud-function"
  function_service_account_email  = module.service_account_auth.service_account_email
  function_service_account_member = module.service_account_auth.service_account_member
  function_entrypoint             = "run"
  target_bucket_name              = "example-trigger-bucket"
  function_contents = [
    {
      filename = "main.py",
      filepath = abspath("./source/main.py")
    },
    {
      filename = "requirements.txt",
      filepath = abspath("./source/requirements.txt")
    }
  ]

  function_environment_variables = {
    OUTPUT_BUCKET = module.gcp_results_bucket.bucket_name
  }

  providers = {
    google.auth_session = google.auth_session
  }
}