resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "scaleway_instance_server" "server" {
  name  = "${var.namespace}-${random_string.suffix.result}-${var.name}"
  image = var.image
  type  = var.type
}
