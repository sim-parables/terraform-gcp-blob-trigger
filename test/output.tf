output "results_bucket_name" {
  description = "GCS Results Bucket Name"
  value       = module.gcp_results_bucket.bucket_name
}

output "trigger_bucket_name" {
  description = "GCS Trigger Bucket Name"
  value       = module.gcp_cloud_function.trigger_bucket_name
}

output "function_name" {
  description = "GCS Trigger Bucket Name"
  value       = module.gcp_cloud_function.function_name
}

output "service_account" {
  description = "GCP Blob Trigger Architecture Service Account"
  value       = module.service_account_auth.service_account_email
  sensitive   = true
}

output "service_account_access_token" {
  description = "Service Account Access Token"
  value       = module.service_account_auth.access_token
  sensitive   = true
}