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
