resource "cloudflare_dns_record" "protonmail_verification" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "@"
  type    = "TXT"
  content = "protonmail-verification=e9457a054010bbbb12cc4abfce39d67198e9abd1"
  ttl     = 1
  comment = "protonmail verification"
}

resource "cloudflare_dns_record" "pm_verification" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "@"
  type    = "TXT"
  content = "pm-verification=yulfrkphygclvbkaipymgmyhstrxuj"
  ttl     = 1
  comment = "pm verification"
}
