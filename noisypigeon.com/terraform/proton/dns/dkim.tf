resource "cloudflare_dns_record" "dkim_primary" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "dkim._domainkey"
  type    = "CNAME"
  content = "dkim._domainkey.alias.proton.me"
  ttl     = 1
  proxied = false
  comment = "proton primary dkim"
}

resource "cloudflare_dns_record" "dkim_secondary" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "dkim02._domainkey"
  type    = "CNAME"
  content = "dkim02._domainkey.alias.proton.me"
  ttl     = 1
  proxied = false
  comment = "proton secondary dkim"
}

resource "cloudflare_dns_record" "dkim_tertiary" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "dkim03._domainkey"
  type    = "CNAME"
  content = "dkim03._domainkey.alias.proton.me"
  ttl     = 1
  proxied = false
  comment = "fastmail tertiary dkim"
}
