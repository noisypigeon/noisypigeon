output "name" {
  description = "State bucket name -- hand-copy into noisypigeon.com/secrets.enc's NOISYPIGEON_COM_TERRAFORM_STATE_BUCKET_NAME"
  value       = module.bucket.name
}
