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