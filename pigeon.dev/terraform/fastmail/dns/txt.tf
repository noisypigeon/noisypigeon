resource "cloudflare_dns_record" "spf" {
  zone_id = local.zone_id_pigeon_dev
  name    = "@"
  type    = "TXT"
  content = "\"v=spf1 include:spf.messagingengine.com ?all\""
  ttl     = 1
  comment = "fastmail spf"
}
