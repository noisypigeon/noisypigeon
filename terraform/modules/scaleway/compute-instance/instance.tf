resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "scaleway_instance_ip" "ipv6" {
  count = var.enable_ipv6 ? 1 : 0
  type  = "routed_ipv6"
}

locals {
  cloud_init = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: false
    packages:
      - rclone
      - neovim

    write_files:
      - path: /root/.config/rclone/rclone.conf
        permissions: '0600'
        defer: true
        content: |
          %{~for bucket in var.buckets~}
          [${bucket.bucket_alias}]
          type = alias
          remote = ${bucket.bucket_name}:${bucket.bucket_name}
          [${bucket.bucket_name}]
          type = s3
          provider = ${bucket.bucket_provider}
          access_key_id = ${bucket.bucket_access_key}
          secret_access_key = ${bucket.bucket_secret_key}
          endpoint = ${bucket.bucket_endpoint}
          acl = private
          no_check_bucket = true
          %{~endfor~}
  EOF
}

resource "terraform_data" "cloud_init" {
  input = md5(local.cloud_init)
}

resource "scaleway_instance_server" "server" {
  name                  = "${var.namespace}-${random_string.suffix.result}-${var.name}"
  image                 = var.image
  type                  = var.type
  ip_id                 = var.enable_ipv6 ? scaleway_instance_ip.ipv6[0].id : null
  tags                  = [for key in var.ssh_keys : "AUTHORIZED_KEY=${replace(key, " ", "_")}"]
  additional_volume_ids = var.additional_volume_ids

  user_data = {
    cloud-init = local.cloud_init
  }

  lifecycle {
    replace_triggered_by = [terraform_data.cloud_init.output]
  }
}
