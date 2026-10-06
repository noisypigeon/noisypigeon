include "root" {
  path = "${get_repo_root()}/workloads/root.hcl"
}

terraform {
  source = get_terragrunt_dir()
}
