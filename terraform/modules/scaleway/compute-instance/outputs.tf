output "id" {
  description = "Instance ID"
  value       = scaleway_instance_server.server.id
}

output "name" {
  description = "Computed instance name"
  value       = scaleway_instance_server.server.name
}

output "public_ips" {
  description = "Public IPs attached to the instance"
  value       = scaleway_instance_server.server.public_ips
}

output "private_ips" {
  description = "Private IPs attached to the instance"
  value       = scaleway_instance_server.server.private_ips
}
