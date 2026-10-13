resource "cloudflare_dns_record" "site_verification" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "@"
  type    = "TXT"
  content = "\"google-site-verification=vFu1wL_0hoMl6UpTkWZ3IiVSlfOvGuY_wtYfpWOrsfA\""
  ttl     = 3600
}
