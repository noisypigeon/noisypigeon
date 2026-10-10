module "key" {
  source       = "https://pigeon.dev/modules/backblaze/api-key/v0.1.1"
  key_name     = "${module.bucket.bucket_name}-key"
  bucket_ids   = [module.bucket.bucket_id]
  capabilities = local.key_capabilities
}

output "application_key_id" {
  value       = module.key.application_key_id
  description = "application_key_id"
}

output "application_key" {
  value       = module.key.application_key
  description = "application_key"
  sensitive   = true
}
