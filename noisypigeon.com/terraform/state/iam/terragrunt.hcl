include "root" {
  path = "${get_repo_root()}/root.hcl"
}

terraform {
  source = get_terragrunt_dir()
}
