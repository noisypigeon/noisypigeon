# DNS record to point pigeon.dev's apex at the Scaleway object-bucket
# website endpoint. Cloudflare-proxied (unlike noisypigeon.com/blog's
# DNS-only CNAMEs) because the bucket's website endpoint has no valid TLS
# cert for this custom hostname -- Cloudflare terminates TLS and proxies
# through.
#
# www is handled by a redirect rule (redirect.tf), not a second direct
# CNAME: confirmed live that Scaleway's bucket-website gateway resolves
# the bucket from the incoming Host header, not the CNAME target --
# www.pigeon.dev as a direct CNAME to the same target 404s with
# NoSuchBucket ("www.pigeon.dev"), since no bucket by that name exists.

resource "cloudflare_dns_record" "root_cname" {
  zone_id = local.zone_id_pigeon_dev
  name    = "@"
  type    = "CNAME"
  content = "pigeon.dev.s3-website.fr-par.scw.cloud"
  proxied = true
  ttl     = 1
  comment = "scaleway object-bucket website endpoint (apex, cloudflare-proxied for TLS)"
}

resource "cloudflare_dns_record" "placeholder_www" {
  zone_id = local.zone_id_pigeon_dev
  name    = "www"
  type    = "CNAME"
  content = "pigeon.dev"
  proxied = true
  ttl     = 1
  comment = "placeholder so Cloudflare intercepts www traffic for the redirect in redirect.tf"
}
