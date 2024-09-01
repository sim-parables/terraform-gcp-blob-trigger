<p float="left">
  <img id="b-0" src="https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white" height="25px"/>
  <img id="b-1" src="https://img.shields.io/badge/Google_Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white" height="25px"/>
  <img id="b-2" src="https://img.shields.io/github/actions/workflow/status/sim-parables/terraform-gcp-blob-trigger/tf-integration-test.yml?style=flat&logo=github&label=CD%20(September%202024)" height="25px"/>
</p>

# Terraform GCP Blob Trigger Module

A reusable module for creating & configuring GCS Buckets with custom Blob Trigger Functions.

## Usage

```hcl
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
  source = "github.com/sim-parables/terraform-gcp-service-account.git"

  IMPERSONATE_SERVICE_ACCOUNT_EMAIL = var.IMPERSONATE_SERVICE_ACCOUNT_EMAIL
  new_service_account_name          = "example-tf-sa"
  roles_list = [
    "roles/storage.admin",
    "roles/cloudfunctions.admin",
    "roles/iam.serviceAccountUser",
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

```

## Inputs

| Name                            | Description                           | Type           | Required |
|:--------------------------------|:--------------------------------------|:---------------|:---------|
| function_name                   | Cloud Function Name                   | string         | Yes      |
| function_service_account_email  | Existing SA with pre-binded IAM Roles | String         | Yes      |
| function_service_account_member | Existing SA's Member ID               | List           | Yes      |
| function_contents               | Cloud Function Code Base file paths   | List(Object()) | Yes      |
| function_entrypoint             | Cloud Function entrypoint func name   | String         | Yes      |
| target_bucket_name              | Target GCS Bucket Name                | String         | No       |
| function_bucket_name            | GCS Function Source Bucket Name       | String         | No       |
| function_memory                 | GCP Function memory size              | Number         | No       |
| function_runtime                | GCP Function Runtime Environment      | String         | No       |
| function_description            | GCP Function Pipeline Description     | String         | No       |
| function_timeout                | GCP Function Timeout Duration in Sec. | Number         | No       |
| function_environment_variables  | Addition. GCP Cloud Function Env Vars | Object()       | No       |  

## Outputs

| Name                   | Description                            |
|:-----------------------|:---------------------------------------|
| trigger_bucket_name    | GCS Trigger Bucket Name                |
| function_name          | GCP Cloud Function Name                |
