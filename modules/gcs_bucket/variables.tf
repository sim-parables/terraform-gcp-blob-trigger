## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "bucket_name" {
  type        = string
  description = "GCS Storage Bucket Name"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "storage_class" {
  type        = string
  description = "GCS Blob Storage Type"
  default     = "standard"
}

variable "storage_location" {
  type        = string
  description = "GCS Blob Storage Region"
  default     = "us-east1"
}