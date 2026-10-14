module "project" {
  source = "https://pigeon.dev/modules/scaleway/project/v2.0.0"
  name   = local.name
}

# LIB-0002 phase C: throwaway change to force a plan through the new
# pinned terragrunt-run ref. Not for merge.
