resource "cloudflare_dns_record" "placeholder_apex" {
  zone_id = local.zone_id_willowgraysen_com
  name    = "@"
  type    = "A"
  content = "192.0.2.1"
  proxied = true
  ttl     = 1
  comment = "placeholder so Cloudflare intercepts apex traffic for the noisypigeon.com redirect"
}

resource "cloudflare_dns_record" "placeholder_www" {
  zone_id = local.zone_id_willowgraysen_com
  name    = "www"
  type    = "CNAME"
  content = "willowgraysen.com"
  proxied = true
  ttl     = 1
  comment = "placeholder so Cloudflare intercepts www traffic for the noisypigeon.com redirect"
}
