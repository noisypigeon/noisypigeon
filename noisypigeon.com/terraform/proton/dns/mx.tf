resource "cloudflare_dns_record" "mx_primary" {
  zone_id  = local.zone_id_noisypigeon_com
  name     = "@"
  type     = "MX"
  content  = "mx1.alias.proton.me"
  priority = 10
  ttl      = 1 # Auto
  comment  = "protonmail primary mx"
}

resource "cloudflare_dns_record" "mx_secondary" {
  zone_id  = local.zone_id_noisypigeon_com
  name     = "@"
  type     = "MX"
  content  = "mx2.alias.proton.me"
  priority = 20
  ttl      = 1 # Auto
  comment  = "protonmail secondary mx"
}
