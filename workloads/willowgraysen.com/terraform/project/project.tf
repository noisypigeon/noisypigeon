module "project" {
  source = "https://noisypigeon.com/modules/scaleway/project/v1.0.0"
  name   = "willowgraysen"
  ssh_key = {
    alias = "noisypigeon"
    # Not a secret; this is my pub key.
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDKsmUsSyZRo1u8TLkz+kJVbxuYsrs3M3tBXpI3HVHQa" #gitleaks:allow
  }
}
