resource "cloudflare_dns_record" "placeholder_apex" {
  zone_id = local.cloudflare_pigeon_dev_zone_id
  name    = "@"
  type    = "A"
  content = "192.0.2.1"
  proxied = true
  ttl     = 1
  comment = "placeholder so Cloudflare intercepts apex traffic for the noisypigeon.com redirect"
}

resource "cloudflare_dns_record" "placeholder_www" {
  zone_id = local.cloudflare_pigeon_dev_zone_id
  name    = "www"
  type    = "CNAME"
  content = "pigeon.dev"
  proxied = true
  ttl     = 1
  comment = "placeholder so Cloudflare intercepts www traffic for the noisypigeon.com redirect"
}
