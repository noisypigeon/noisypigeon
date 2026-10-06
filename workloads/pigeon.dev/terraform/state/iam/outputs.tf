output "access_key" {
  description = "IAM API key access key -- hand-copy into workloads/pigeon.dev/secrets.enc's SCALEWAY_ACCESS_KEY"
  value       = module.iam_api_key.access_key
  sensitive   = true
}

output "secret_key" {
  description = "IAM API key secret key -- hand-copy into workloads/pigeon.dev/secrets.enc's SCALEWAY_SECRET_KEY"
  value       = module.iam_api_key.secret_key
  sensitive   = true
}
