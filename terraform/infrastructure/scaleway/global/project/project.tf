module "project" {
  source       = "git::https://github.com/noisypigeon/pigeon.git//terraform/modules/scaleway/project?ref=terraform/modules/scaleway/project/v0.2.1"
  name         = "noisypigeon"
  ssh_key = {
    alias      = local.ssh_key_alias
    public_key = local.ssh_key_public_key
  }
}
