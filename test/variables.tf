## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "IMPERSONATE_SERVICE_ACCOUNT_EMAIL" {
  type        = string
  description = <<EOT
    GCP Service Account Email equiped with sufficient Project IAM roles to create new Service Accounts.
    Please set using an ENV variable with TF_VAR_IMPERSONATE_SERVICE_ACCOUNT_EMAIL, and avoid hard coding
    in terraform.tfvars
  EOT
}

variable "POOL_ID" {
  type        = string
  description = "GCP Worflow Identify Federation Pool ID"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "GITHUB_REPOSITORY_OWNER" {
  type        = string
  description = "Github Actions Default ENV Variable for the Repo Owner"
  default     = "sim-parables"
}

variable "GITHUB_REPOSITORY" {
  type        = string
  description = "Github Actions Default ENV Variable for the Repo Path"
  default     = "sim-parables/terraform-gcp-blob-trigger"
}

variable "GITHUB_REF" {
  type        = string
  description = "Github Actions Default ENV Variable for full form of the Branch or Tag"
  default     = null
}

variable "GITHUB_ENV" {
  type        = string
  description = <<EOT
    Github Environment in which the Action Workflow's Job or Step is running. Ex: production.
    This is not found in Github Action's Default Environment Variables and will need to be
    defined manually.
  EOT
  default     = null
}