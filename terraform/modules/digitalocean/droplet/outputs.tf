output "name" {
  description = "Computed droplet name"
  value       = digitalocean_droplet.droplet.name
}

output "urn" {
  description = "Droplet URN"
  value       = digitalocean_droplet.droplet.urn
}

output "id" {
  description = "Droplet ID"
  value       = digitalocean_droplet.droplet.id
}

output "ipv4_address" {
  description = "Droplet IPv4 address"
  value       = digitalocean_droplet.droplet.ipv4_address
}
