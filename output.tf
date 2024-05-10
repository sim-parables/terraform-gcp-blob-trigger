output "trigger_bucket_name" {
  description = "GCS Trigger Bucket Name"
  value       = module.trigger_bucket.bucket_name
}

output "function_name" {
  description = "GCP Cloud Function Name"
  value       = google_cloudfunctions_function.this.name
}