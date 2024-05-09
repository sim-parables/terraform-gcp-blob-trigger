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

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------
