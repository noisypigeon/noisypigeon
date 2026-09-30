locals {
  # Secrets: read from this provider's own ".env" file (scaleway/.env),
  # found the same way every leaf finds this root.hcl itself (nearest
  # ancestor). Backend credentials (SCALEWAY_ACCESS_KEY/SCALEWAY_SECRET_KEY)
  # are the same ones used by the provider block below — scaleway/* has its
  # own dedicated state bucket, not the digitalocean/cloudflare shared one —
  # see docs/adr/0062-scaleway-remote-state.md.
  root_env_path = find_in_parent_folders(".env", "")

  root_secrets = { for pair in [
    for line in split("\n", fileexists(local.root_env_path) ? file(local.root_env_path) : "") :
    regex("^([^=]+)=(.*)$", trimspace(line))
    if trimspace(line) != "" && !startswith(trimspace(line), "#")
    && can(regex("^([^=]+)=(.*)$", trimspace(line)))
  ] : trimspace(pair[0]) => trimspace(pair[1]) }

  secrets = local.root_secrets

  # Region/zone selection: keyed off the leaf's own path, so `fr-par/*` and
  # `nl-ams/*` leaves get their own provider region/zone from one shared
  # root.hcl instead of a second per-region root file — see
  # docs/adr/0080-add-scaleway-nl-ams-region.md. Anything else (e.g.
  # `global/*`) falls through to the `fr-par` default.
  leaf_path           = path_relative_to_include()
  leaf_region_segment = element(split("/", local.leaf_path), 0)
  scaleway_region_zone = {
    "fr-par" = { region = "fr-par", zone = "fr-par-1" }
    "nl-ams" = { region = "nl-ams", zone = "nl-ams-1" }
  }
  scaleway_region = lookup(local.scaleway_region_zone, local.leaf_region_segment, local.scaleway_region_zone["fr-par"]).region
  scaleway_zone   = lookup(local.scaleway_region_zone, local.leaf_region_segment, local.scaleway_region_zone["fr-par"]).zone

  # Injected secrets/sensitive values: any .env key prefixed ENV_SW_ is exposed as a
  # local named. See docs/adr/0006-automatic-bucket-name-locals.md.
  bucket_name_secrets = {
    for k, v in local.secrets : "${lower(trimprefix(k, "ENV_SW_"))}" => get_env(k, v)
    if startswith(k, "ENV_SW_")
  }
}

generate "bucket_names" {
path      = "bucket_names_generated.tf"
if_exists = "overwrite"
contents  = <<EOF
locals {
${join("\n", [for k, v in local.bucket_name_secrets : "  ${k} = \"${v}\""])}
}
EOF
}


generate "provider" {
  path      = "provider_generated.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
  }
}

provider "scaleway" {
  access_key      = "${get_env("SCALEWAY_ACCESS_KEY", lookup(local.secrets, "SCALEWAY_ACCESS_KEY", ""))}"
  secret_key      = "${get_env("SCALEWAY_SECRET_KEY", lookup(local.secrets, "SCALEWAY_SECRET_KEY", ""))}"
  organization_id = "${get_env("SCALEWAY_ORGANIZATION_ID", lookup(local.secrets, "SCALEWAY_ORGANIZATION_ID", ""))}"
  zone   = "${local.scaleway_zone}"
  region = "${local.scaleway_region}"
}
EOF
}

generate "scaleway_ids" {
  path      = "scaleway_ids_generated.tf"
  if_exists = "overwrite"
  contents  = <<EOF
locals {
  scaleway_organization_id            = "${get_env("SCALEWAY_ORGANIZATION_ID", lookup(local.secrets, "SCALEWAY_ORGANIZATION_ID", ""))}"
  scaleway_project_id_noisypigeon = "${get_env("SCALEWAY_PROJECT_ID_NOISYPIGEON", lookup(local.secrets, "SCALEWAY_PROJECT_ID_NOISYPIGEON", ""))}"
}
EOF
}

# Configure backend to use Scaleway's own Object Storage bucket, not the
# digitalocean/cloudflare shared Spaces bucket — see
# docs/adr/0062-scaleway-remote-state.md.
remote_state {
  backend = "s3"

  config = {
    endpoints = {
      s3 = "https://s3.fr-par.scw.cloud"
    }
    region                      = "fr-par"
    bucket                      = lookup(local.secrets, "SCALEWAY_TERRAFORM_STATE_BUCKET_NAME", "")
    key                         = "scaleway/${path_relative_to_include()}/terraform.tfstate"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true

    access_key = get_env("SCALEWAY_ACCESS_KEY", lookup(local.secrets, "SCALEWAY_ACCESS_KEY", ""))
    secret_key = get_env("SCALEWAY_SECRET_KEY", lookup(local.secrets, "SCALEWAY_SECRET_KEY", ""))
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
}
