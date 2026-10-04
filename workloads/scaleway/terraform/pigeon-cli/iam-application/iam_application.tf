module "iam_application" {
  source      = "https://noisypigeon.com/modules/scaleway/iam-application/v0.1.0"
  name        = "pigeon-cli"
  description = "Shared IAM application for every pigeon-cli job policy"
}

output "id" {
  description = "Shared pigeon-cli IAM application ID -- hand-copy into the repo's root .env as PIGEON_CLI_IAM_APPLICATION_ID"
  value       = module.iam_application.id
}
