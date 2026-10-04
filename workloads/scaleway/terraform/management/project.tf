module "project" {
  source = "https://noisypigeon.com/modules/scaleway/project/v1.0.0"
  name   = "noisypigeon"
  ssh_key = {
    alias      = local.ssh_key_alias
    public_key = local.ssh_key_public_key
  }
}
