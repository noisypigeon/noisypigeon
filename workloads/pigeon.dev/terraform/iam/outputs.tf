output "access_key" {
  description = "IAM API key access key -- hand-copy into the PIGEON_DEV_SCW_ACCESS_KEY GitHub Actions secret after applying"
  value       = module.iam_api_key.access_key
  sensitive   = true
}

output "secret_key" {
  description = "IAM API key secret key -- hand-copy into the PIGEON_DEV_SCW_SECRET_KEY GitHub Actions secret after applying"
  value       = module.iam_api_key.secret_key
  sensitive   = true
}
