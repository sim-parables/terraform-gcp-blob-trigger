output "bucket_name" {
  description = "GCS Storage Bucket Name"
  value       = google_storage_bucket.this.name
}

output "bucket_location" {
  description = "GCS Storage Bucket Location"
  value       = google_storage_bucket.this.location
}