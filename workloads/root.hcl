locals {
  # Secrets: read from the shared repo-root ".env" file, found by walking up
  # from this leaf's directory -- see docs/adr/0063-shared-root-env-and-cloudflare-migration.md.
  root_env_path = find_in_parent_folders(".env", "")

  root_secrets = { for pair in [
    for line in split("\n", fileexists(local.root_env_path) ? file(local.root_env_path) : "") :
    regex("^([^=]+)=(.*)$", trimspace(line))
    if trimspace(line) != "" && !startswith(trimspace(line), "#")
    && can(regex("^([^=]+)=(.*)$", trimspace(line)))
  ] : trimspace(pair[0]) => trimspace(pair[1]) }

  secrets = local.root_secrets

  # pigeon.dev's zone was moved onto the same Cloudflare account as
  # noisypigeon.com, but the API token used here remains zone-scoped per
  # domain regardless -- confirmed live while migrating ADR-0096's fastmail
  # leaves: CLOUDFLARE_NOISYPIGEON_COM_TOKEN gets a hard "Authentication
  # error" (code 10000) against the pigeon.dev zone's DNS records, while
  # CLOUDFLARE_PIGEON_DEV_TOKEN succeeds. So, like the old (now-deleted)
  # cloudflare/root.hcl (see
  # docs/adr/0064-merge-pigeon-dev-into-cloudflare-root.md), credentials
  # still branch per leaf by path -- just keyed off any path segment being
  # "pigeon.dev" rather than a fixed "global/pigeon.dev/" prefix, since
  # workloads/ leaves can nest a domain segment at any depth.
  is_pigeon_dev_leaf = contains(local.path_segments, "pigeon.dev")

  cloudflare_api_token  = local.is_pigeon_dev_leaf ? get_env("CLOUDFLARE_PIGEON_DEV_TOKEN", lookup(local.secrets, "CLOUDFLARE_PIGEON_DEV_TOKEN", "")) : get_env("CLOUDFLARE_NOISYPIGEON_COM_TOKEN", lookup(local.secrets, "CLOUDFLARE_NOISYPIGEON_COM_TOKEN", ""))
  cloudflare_account_id = local.is_pigeon_dev_leaf ? get_env("CLOUDFLARE_PIGEON_DEV_ACCOUNT_ID", lookup(local.secrets, "CLOUDFLARE_PIGEON_DEV_ACCOUNT_ID", "")) : get_env("CLOUDFLARE_NOISYPIGEON_COM_ACCOUNT_ID", lookup(local.secrets, "CLOUDFLARE_NOISYPIGEON_COM_ACCOUNT_ID", ""))

  scaleway_access_key      = get_env("SCALEWAY_ACCESS_KEY", lookup(local.secrets, "SCALEWAY_ACCESS_KEY", ""))
  scaleway_secret_key      = get_env("SCALEWAY_SECRET_KEY", lookup(local.secrets, "SCALEWAY_SECRET_KEY", ""))
  scaleway_organization_id = get_env("SCALEWAY_ORGANIZATION_ID", lookup(local.secrets, "SCALEWAY_ORGANIZATION_ID", ""))

  ssh_key_alias      = get_env("ENV_SW_SSH_KEY_ALIAS", lookup(local.secrets, "ENV_SW_SSH_KEY_ALIAS", ""))
  ssh_key_public_key = get_env("ENV_SW_SSH_KEY_PUBLIC_KEY", lookup(local.secrets, "ENV_SW_SSH_KEY_PUBLIC_KEY", ""))

  # Enforce the workloads/<name>/terraform convention: exclude any leaf
  # whose path relative to this root.hcl doesn't start with
  # "<name>/terraform" from run --all -- see
  # docs/adr/0092-move-github-pages-leaf-to-workloads-blog-terraform.md.
  # (The old top-level `skip` attribute is deprecated in Terragrunt 1.x;
  # `exclude` is its replacement and -- confirmed -- works correctly when
  # set inside a root.hcl included by leaf terragrunt.hcl files.)
  # Widened from "exactly 2 segments" to "any depth under <name>/terraform/"
  # by docs/adr/0096-move-fastmail-leaves-to-workloads-email-terraform.md,
  # to admit per-domain nested leaves like email/terraform/fastmail/<domain>.
  path_segments = split("/", path_relative_to_include())
  is_valid_leaf = length(local.path_segments) >= 2 && local.path_segments[1] == "terraform"

  # Per-leaf Scaleway region/zone override -- see
  # docs/adr/0098-decommission-terraform-infrastructure.md. Every leaf is
  # fr-par by default; a leaf needing a different region (so far, only
  # custodian-buckets/terraform/duck-jellyfish, nl-ams) drops a
  # workload_definition.hcl next to its own terragrunt.hcl declaring its
  # own `scaleway_region`/`scaleway_zone` locals. This root.hcl reads that
  # file via read_terragrunt_config, which returns the given default
  # untouched if the file doesn't exist -- no error, no change for every
  # other leaf. The leaf's absolute directory is computed from two
  # primitives already proven correct elsewhere in this same file
  # (find_in_parent_folders for this root.hcl's own location,
  # path_relative_to_include for the leaf's position under it) rather than
  # relying on get_terragrunt_dir()'s parent-vs-child-scope semantics,
  # which weren't worth the risk of getting wrong here.
  workload_dir             = dirname(find_in_parent_folders("root.hcl"))
  workload_definition_path = "${local.workload_dir}/${path_relative_to_include()}/workload_definition.hcl"
  workload_definition      = read_terragrunt_config(local.workload_definition_path, { locals = {} })
  scaleway_region          = lookup(local.workload_definition.locals, "scaleway_region", "fr-par")
  scaleway_zone            = lookup(local.workload_definition.locals, "scaleway_zone", "fr-par-1")

  # Injected secrets/sensitive values: any .env key prefixed ENV_SW_ is exposed as a
  # local named. See docs/adr/0006-automatic-bucket-name-locals.md.
  bucket_name_secrets = {
    for k, v in local.secrets : "${lower(trimprefix(k, "ENV_SW_"))}" => get_env(k, v)
    if startswith(k, "ENV_SW_")
  }
}

exclude {
  if      = !local.is_valid_leaf
  actions = ["all_except_output"]
}

generate "bucket_name_secrets" {
  path      = "bucket_name_secrets_generated.tf"
  if_exists = "overwrite"
  contents  = <<EOF
  locals {
  ${join("\n", [for k, v in local.bucket_name_secrets : "  ${k} = \"${v}\""])}
  }
  EOF
}

generate "cloudflare_ids" {
  path      = "cloudflare_ids_generated.tf"
  if_exists = "overwrite"
  contents  = <<EOF
locals {
  cloudflare_account_id              = "${local.cloudflare_account_id}"
  cloudflare_noisypigeon_com_zone_id = "${get_env("CLOUDFLARE_NOISYPIGEON_COM_ZONE_ID", lookup(local.secrets, "CLOUDFLARE_NOISYPIGEON_COM_ZONE_ID", ""))}"
  cloudflare_pigeon_dev_zone_id      = "${get_env("CLOUDFLARE_PIGEON_DEV_ZONE_ID", lookup(local.secrets, "CLOUDFLARE_PIGEON_DEV_ZONE_ID", ""))}"
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
  scaleway_organization_id        = "${local.scaleway_organization_id}"
  scaleway_project_id_noisypigeon = "${get_env("SCALEWAY_PROJECT_ID_NOISYPIGEON", lookup(local.secrets, "SCALEWAY_PROJECT_ID_NOISYPIGEON", ""))}"

  # One shared Cockpit metrics/logs source + push token for every
  # pigeon-cli compute instance, rather than one private source per leaf
  # (docs/adr/0103-shared-cockpit-store.md) -- provisioned once by
  # workloads/pigeon-cli/terraform/observability/, then hand-copied into
  # this repo's shared root .env the same manual way
  # SCALEWAY_ACCESS_KEY/SCALEWAY_PROJECT_ID_NOISYPIGEON already are.
  pigeon_cockpit_metrics_push_url = "${get_env("PIGEON_COCKPIT_METRICS_PUSH_URL", lookup(local.secrets, "PIGEON_COCKPIT_METRICS_PUSH_URL", ""))}"
  pigeon_cockpit_logs_push_url    = "${get_env("PIGEON_COCKPIT_LOGS_PUSH_URL", lookup(local.secrets, "PIGEON_COCKPIT_LOGS_PUSH_URL", ""))}"
  pigeon_cockpit_token_secret     = "${get_env("PIGEON_COCKPIT_TOKEN_SECRET", lookup(local.secrets, "PIGEON_COCKPIT_TOKEN_SECRET", ""))}"
}
EOF
}

# Scaleway S3-compatible state bucket -- see
# docs/adr/0062-scaleway-remote-state.md. This is the state bucket's own
# fixed location, always fr-par, regardless of any given leaf's own
# scaleway_region/scaleway_zone above -- see docs/adr/0098.
remote_state {
  backend = "s3"

  config = {
    endpoints = {
      s3 = "https://s3.fr-par.scw.cloud"
    }
    region                      = "fr-par"
    bucket                      = lookup(local.secrets, "SCALEWAY_TERRAFORM_STATE_BUCKET_NAME", "")
    key                         = "workloads/${path_relative_to_include()}/terraform.tfstate"
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
