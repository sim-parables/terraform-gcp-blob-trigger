## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "function_name" {
  type        = string
  description = "GCP Function Pipeline Name"
}

variable "function_service_account_email" {
  type        = string
  description = "GCP Service Account Email (pre-strapped with required Project IAM Role Bindings)"
}

variable "function_service_account_member" {
  type        = string
  description = "GCP Service Account Member Details (pre-strapped with required Project IAM Role Bindings)"
}

variable "function_contents" {
  type = list(object({
    filepath = string,
    filename = string
  }))
  description = "Full File Paths to Function's Source Code to Zip into single Artifact"
}

variable "function_entrypoint" {
  type        = string
  description = "Function to Run from Source Code Once Triggered"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "target_bucket_name" {
  type        = string
  description = "Target GCS Bucket Name"
  default     = "blob-trigger-bucket"
}

variable "function_bucket_name" {
  type        = string
  description = "GCS Function Source Bucket Name"
  default     = "blob-trigger-source-bucket"
}

variable "function_memory" {
  type        = number
  description = "GCP Function memory size"
  default     = 256
}

variable "function_runtime" {
  type        = string
  description = "GCP Function Runtime Environment"
  default     = "python310"
}

variable "function_description" {
  type        = string
  description = "GCP Function Pipeline Description"
  default     = "Sim-Parables GCP Function for Demonstrating Blob Triggers"
}

variable "function_timeout" {
  type        = number
  description = "GCP Function Timeout Duration in Seconds"
  default     = 60
}

variable "function_environment_variables" {
  type        = map(any)
  description = "Additional GCP Cloud Function Environment Variables to include"
  default     = {}
}