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

resource "scaleway_instance_ip" "ipv4" {
  count = var.enable_ipv4 ? 1 : 0
  type  = "routed_ipv4"
}

locals {
  cloud_init = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: false
    packages:
    %{~if var.profile == "docker"~}
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - lsb-release
    %{~endif~}
    %{~if var.profile == "pigeon-cli"~}
      - rclone
      - neovim
    %{~endif~}
    %{~if var.profile == "pigeon-cli"~}

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
      - path: /root/.config/pigeon/keyring.toml
        permissions: '0600'
        defer: true
        content: |
          %{~for entry in var.keyring_entries~}
          [[entries]]
          kind = "${entry.kind}"
          alias = "${entry.alias}"
          %{~if entry.kind == "email"~}
          email = "${entry.email}"
          provider = "${entry.provider}"
          host = "${entry.host}"
          port = ${entry.port}
          %{~if entry.max_imap_connections != null~}
          max_imap_connections = ${entry.max_imap_connections}
          %{~endif~}
          %{~endif~}
          %{~if entry.kind == "bucket"~}
          endpoint = "${entry.endpoint}"
          bucket = "${entry.bucket}"
          access_key_id = "${entry.access_key_id}"
          encryption_key_alias = "${entry.encryption_key_alias}"
          %{~endif~}
          %{~if entry.kind == "encryption-key"~}
          created_at = "${entry.created_at}"
          %{~endif~}

          %{~endfor~}
    %{~endif~}

    runcmd:
      - export HOME=/root
    %{~if length(var.additional_volume_ids) > 0~}
      - mkfs.ext4 -L data /dev/sdb
      - mkdir -p /mnt/data
      - mount /dev/sdb /mnt/data
      - UUID=$(blkid -s UUID -o value /dev/sdb)
      - echo "UUID=$UUID /mnt/data ext4 defaults,nofail 0 2" >> /etc/fstab
      - mount -a
    %{~endif~}
      - curl -fsSL https://mise.run | sh
      - echo 'eval "$(/root/.local/bin/mise activate bash)"' >> /root/.bashrc
    %{~if var.profile == "docker"~}
      - mkdir -p /etc/apt/keyrings
      - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
      - apt-get update
      - apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
      - systemctl enable docker
      - systemctl start docker
    %{~endif~}
    %{~if var.profile == "pigeon-cli"~}
      - curl -fsSL https://gist.githubusercontent.com/noisypigeon/1e96e8ef94380f913f6ae02782965149/raw/pigeon.sh | bash
    %{~endif~}
  EOF
}

resource "terraform_data" "cloud_init" {
  input = md5(local.cloud_init)
}

resource "scaleway_instance_server" "server" {
  name  = "${var.namespace}-${random_string.suffix.result}-${var.name}"
  image = var.image
  type  = var.type
  ip_ids = compact([
    var.enable_ipv4 ? scaleway_instance_ip.ipv4[0].id : null,
    var.enable_ipv6 ? scaleway_instance_ip.ipv6[0].id : null,
  ])
  tags                  = [for key in var.ssh_keys : "AUTHORIZED_KEY=${replace(key, " ", "_")}"]
  additional_volume_ids = var.additional_volume_ids

  user_data = {
    cloud-init = local.cloud_init
  }

  lifecycle {
    replace_triggered_by = [terraform_data.cloud_init.output]
  }
}
