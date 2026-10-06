# DNS record to point noisypigeon.com's apex at the Scaleway object-bucket
# website endpoint. Cloudflare-proxied (the bucket's website endpoint has
# no valid TLS cert for this custom hostname -- Cloudflare terminates TLS
# and proxies through), replacing the former DNS-only CNAME to
# noisypigeon.github.io (GitHub Pages) -- see ADR-0132.
#
# www is handled by a redirect rule (redirect.tf), not a second direct
# CNAME: Scaleway's bucket-website gateway resolves the bucket from the
# incoming Host header, not the CNAME target -- a direct www CNAME to the
# same target 404s with NoSuchBucket, since no bucket by that name exists
# (confirmed live on pigeon.dev's identical leaf, ADR-0130).

resource "cloudflare_dns_record" "root_cname" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "@"
  type    = "CNAME"
  content = "noisypigeon.com.s3-website.fr-par.scw.cloud"
  proxied = true
  ttl     = 1
  comment = "scaleway object-bucket website endpoint (apex, cloudflare-proxied for TLS)"
}

resource "cloudflare_dns_record" "placeholder_www" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "www"
  type    = "CNAME"
  content = "noisypigeon.com"
  proxied = true
  ttl     = 1
  comment = "placeholder so Cloudflare intercepts www traffic for the redirect in redirect.tf"
}
