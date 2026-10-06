output "name" {
  description = "State bucket name -- hand-copy into workloads/willowgraysen.com/secrets.enc's WILLOWGRAYSEN_COM_TERRAFORM_STATE_BUCKET_NAME"
  value       = module.bucket.name
}
