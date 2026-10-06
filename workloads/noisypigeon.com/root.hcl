locals {
  # Secrets: decrypted in-memory from this workload's own "secrets.enc" file
  # via sops/age -- see docs/adr/0131-workload-specific-secrets.md. Mirrors
  # the shared workloads/root.hcl's own ".env.enc" decryption exactly
  # (docs/adr/0123-sops-encrypted-root-env.md), just scoped to this workload
  # and never merged with or falling back to the repo-root file. No
  # plaintext copy ever touches disk.
  secrets_enc_path = find_in_parent_folders("secrets.enc", "")

  secrets_decrypted = local.secrets_enc_path != "" ? run_cmd(
    "--terragrunt-quiet", "sops", "--decrypt",
    "--input-type", "dotenv", "--output-type", "dotenv",
    local.secrets_enc_path
  ) : ""

  secrets = { for pair in [
    for line in split("\n", local.secrets_decrypted) :
    regex("^([^=]+)=(.*)$", trimspace(line))
    if trimspace(line) != "" && !startswith(trimspace(line), "#")
    && !startswith(trimspace(line), "sops_")
    && can(regex("^([^=]+)=(.*)$", trimspace(line)))
  ] : trimspace(pair[0]) => trimspace(pair[1]) }

  cloudflare_api_token  = get_env("CLOUDFLARE_TOKEN", lookup(local.secrets, "CLOUDFLARE_TOKEN", ""))
  cloudflare_account_id = get_env("CLOUDFLARE_ACCOUNT_ID", lookup(local.secrets, "CLOUDFLARE_ACCOUNT_ID", ""))

  scaleway_access_key      = get_env("SCALEWAY_ACCESS_KEY", lookup(local.secrets, "SCALEWAY_ACCESS_KEY", ""))
  scaleway_secret_key      = get_env("SCALEWAY_SECRET_KEY", lookup(local.secrets, "SCALEWAY_SECRET_KEY", ""))
  scaleway_organization_id = get_env("SCALEWAY_ORGANIZATION_ID", lookup(local.secrets, "SCALEWAY_ORGANIZATION_ID", ""))
  scaleway_project_id      = get_env("SCALEWAY_PROJECT_ID", lookup(local.secrets, "SCALEWAY_PROJECT_ID", ""))

  # Enforce the terraform/<leaf> convention under this workload -- one less
  # path segment than the shared root's own check, since there's no
  # "<workload-name>/" prefix at this level anymore (this root.hcl is
  # already workload-scoped). See docs/adr/0092, docs/adr/0096.
  path_segments = split("/", path_relative_to_include())
  is_valid_leaf = length(local.path_segments) >= 1 && local.path_segments[0] == "terraform"

  # Per-leaf Scaleway region/zone override, same mechanism as the shared
  # root.hcl (docs/adr/0098) -- every leaf defaults to fr-par.
  workload_dir             = dirname(find_in_parent_folders("root.hcl"))
  workload_definition_path = "${local.workload_dir}/${path_relative_to_include()}/scaleway_config.hcl"
  workload_definition      = read_terragrunt_config(local.workload_definition_path, { locals = {} })
  scaleway_region          = lookup(local.workload_definition.locals, "scaleway_region", "fr-par")
  scaleway_zone            = lookup(local.workload_definition.locals, "scaleway_zone", "fr-par-1")

  # Injected secrets/sensitive values: any secrets.enc key prefixed ENV_SW_
  # or ENV_CF_ is exposed as a local named after the rest of the key, same
  # convention as the shared root.hcl -- see docs/adr/0006.
  env_scaleway_secrets = {
    for k, v in local.secrets : "${lower(trimprefix(k, "ENV_SW_"))}" => get_env(k, v)
    if startswith(k, "ENV_SW_")
  }

  env_cloudflare_secrets = {
    for k, v in local.secrets : "${lower(trimprefix(k, "ENV_CF_"))}" => get_env(k, v)
    if startswith(k, "ENV_CF_")
  }

  terraform_state_bucket_name = get_env("NOISYPIGEON_COM_TERRAFORM_STATE_BUCKET_NAME", lookup(local.secrets, "NOISYPIGEON_COM_TERRAFORM_STATE_BUCKET_NAME", ""))
}

exclude {
  if      = !local.is_valid_leaf
  actions = ["all_except_output"]
}

generate "env_scaleway_secrets" {
  path      = "env_scaleway_secrets_generated.tf"
  if_exists = "overwrite"
  contents  = <<EOF
  locals {
  ${join("\n", [for k, v in local.env_scaleway_secrets : "  ${k} = \"${v}\""])}
  }
  EOF
}

generate "cloudflare_ids" {
  path      = "cloudflare_ids_generated.tf"
  if_exists = "overwrite"
  contents  = <<EOF
locals {
  cloudflare_account_id              = "${local.cloudflare_account_id}"
  ${join("\n", [for k, v in local.env_cloudflare_secrets : "  ${k} = \"${v}\""])}
}
EOF
}

generate "provider" {
  path      = "provider_generated.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
  }
}

provider "cloudflare" {
  api_token = "${local.cloudflare_api_token}"
}

provider "scaleway" {
  access_key      = "${local.scaleway_access_key}"
  secret_key      = "${local.scaleway_secret_key}"
  organization_id = "${local.scaleway_organization_id}"
  zone            = "${local.scaleway_zone}"
  region          = "${local.scaleway_region}"
}
EOF
}

generate "scaleway_ids" {
  path      = "scaleway_ids_generated.tf"
  if_exists = "overwrite"
  contents  = <<EOF
locals {
  scaleway_organization_id = "${local.scaleway_organization_id}"
  scaleway_project_id      = "${local.scaleway_project_id}"
  scaleway_s3_provider_name = "Scaleway"
}
EOF
}

# noisypigeon.com's own dedicated Terraform state bucket -- see
# docs/adr/0132-noisypigeon-com-terraform-self-sufficiency.md. Always
# fr-par, regardless of any given leaf's own scaleway_region/scaleway_zone
# above (same convention as the shared root.hcl's state bucket).
remote_state {
  backend = "s3"

  config = {
    endpoints = {
      s3 = "https://s3.fr-par.scw.cloud"
    }
    region                      = "fr-par"
    bucket                      = local.terraform_state_bucket_name
    key                         = "${path_relative_to_include()}/terraform.tfstate"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true

    access_key = local.scaleway_access_key
    secret_key = local.scaleway_secret_key
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
}
