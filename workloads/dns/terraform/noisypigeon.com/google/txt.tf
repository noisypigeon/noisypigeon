resource "cloudflare_dns_record" "site_verification" {
  zone_id = local.cloudflare_noisypigeon_com_zone_id
  name    = "@"
  type    = "TXT"
  content = "\"google-site-verification=vFu1wL_0hoMl6UpTkWZ3IiVSlfOvGuY_wtYfpWOrsfA\""
  ttl     = 3600
}
