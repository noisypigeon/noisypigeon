#
# Instances follow a consistent naming scheme.
# Format: {namespace}-{random_code}-{name}
# I.e. example-com-q82q17-sample
#
variable "namespace" {
  type        = string
  description = "Instance name prefix"
}

variable "name" {
  type        = string
  description = "Instance name suffix"
}

variable "image" {
  type        = string
  description = "Instance image (UUID or marketplace label)"
}

variable "type" {
  type        = string
  description = "Instance commercial type"
  default     = "STARDUST1-S"
}

variable "profile" {
  type        = string
  description = "Cloud-init provisioning profile: \"docker\" (Docker CE), or \"pigeon-cli\" (rclone/neovim + rclone.conf from buckets, plus runs the pigeon-cli bootstrap script directly on first boot)"
  default     = "pigeon-cli"

  validation {
    condition     = contains(["docker", "pigeon-cli"], var.profile)
    error_message = "profile must be \"docker\" or \"pigeon-cli\"."
  }
}

variable "buckets" {
  type = list(object({
    bucket_name       = string
    bucket_alias      = string
    bucket_endpoint   = string
    bucket_access_key = string
    bucket_secret_key = string
    bucket_provider   = string
  }))
  description = "Buckets to configure in rclone; only used when profile = \"pigeon-cli\""
  default     = []

  validation {
    condition     = alltrue([for b in var.buckets : can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", b.bucket_alias))])
    error_message = "Bucket aliases must be lowercase alphanumeric with hyphens."
  }

  validation {
    condition     = length(var.buckets) == length(distinct([for b in var.buckets : b.bucket_alias]))
    error_message = "Bucket aliases must be unique."
  }

  validation {
    condition     = var.profile == "pigeon-cli" || length(var.buckets) == 0
    error_message = "buckets is only used when profile = \"pigeon-cli\"."
  }
}

variable "enable_ipv4" {
  type        = bool
  description = "Create and attach a routed IPv4 address (true/false)"
  default     = true
}

variable "enable_ipv6" {
  type        = bool
  description = "Create and attach a routed IPv6 address (true/false)"
  default     = false
}

variable "ssh_keys" {
  type        = list(string)
  description = "SSH public keys granted instance-specific access via Scaleway's AUTHORIZED_KEY tag convention, in addition to account-wide keys"
  default     = []
}

variable "additional_volume_ids" {
  type        = list(string)
  description = "IDs of pre-created block volumes (e.g. scaleway/block-volume's id output) to attach to the instance"
  default     = []
}
