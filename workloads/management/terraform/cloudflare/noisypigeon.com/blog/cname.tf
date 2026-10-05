# DNS records to point noisypigeon.com (apex + www) to noisypigeon.github.io

resource "cloudflare_dns_record" "root_cname" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "@"
  type    = "CNAME"
  content = "noisypigeon.github.io"
  proxied = false
  ttl     = 1
  comment = "github pages root cname (apex, cloudflare-flattened)"
}

resource "cloudflare_dns_record" "www_cname" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "www"
  type    = "CNAME"
  content = "noisypigeon.github.io"
  proxied = false
  ttl     = 1
  comment = "github pages www cname"
}
