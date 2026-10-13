output "name" {
  description = "State bucket name -- hand-copy into pigeon.dev/secrets.enc's PIGEON_DEV_TERRAFORM_STATE_BUCKET_NAME"
  value       = module.bucket.name
}
