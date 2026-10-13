resource "cloudflare_dns_record" "proton_spf" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "@"
  type    = "TXT"
  content = "v=spf1 include:alias.proton.me ~all"
  ttl     = 1
  comment = "proton spf verification"
}
