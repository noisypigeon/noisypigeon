# DNS records to point pigeon.dev (apex + www) to the Scaleway object-bucket
# website endpoint. Cloudflare-proxied (unlike noisypigeon.com/blog's
# DNS-only CNAMEs) because the bucket's website endpoint has no valid TLS
# cert for this custom hostname -- Cloudflare terminates TLS and proxies
# through. Scaleway resolves which bucket to serve from the CNAME target
# hostname itself (it embeds the bucket name), not from the incoming Host
# header, so both apex and www can point at the same target.

resource "cloudflare_dns_record" "root_cname" {
  zone_id = local.zone_id_pigeon_dev
  name    = "@"
  type    = "CNAME"
  content = "pigeon.dev.s3-website.fr-par.scw.cloud"
  proxied = true
  ttl     = 1
  comment = "scaleway object-bucket website endpoint (apex, cloudflare-proxied for TLS)"
}

resource "cloudflare_dns_record" "www_cname" {
  zone_id = local.zone_id_pigeon_dev
  name    = "www"
  type    = "CNAME"
  content = "pigeon.dev.s3-website.fr-par.scw.cloud"
  proxied = true
  ttl     = 1
  comment = "scaleway object-bucket website endpoint (www)"
}
