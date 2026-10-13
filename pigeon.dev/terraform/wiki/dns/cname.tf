# DNS records to point pigeon.dev (apex + www) at GitHub Pages
# (noisypigeon.github.io) -- ADR-0156 cut the site over from the Scaleway
# bucket this leaf used to front. Both DNS-only (proxied = false), mirroring
# the pre-ADR-0132 noisypigeon.com records exactly: GitHub Pages issues its
# own Let's Encrypt certificate for the custom domain, which it cannot do
# while Cloudflare is proxying (and terminating TLS for) the apex, and it
# redirects www -> apex natively, so no separate redirect rule is needed
# here (ADR-0105's old blog/cname.tf is the last precedent for this shape)

resource "cloudflare_dns_record" "root_cname" {
  zone_id = local.zone_id_pigeon_dev
  name    = "@"
  type    = "CNAME"
  content = "noisypigeon.github.io"
  proxied = false
  ttl     = 1
  comment = "github pages root cname (apex, cloudflare-flattened)"
}

resource "cloudflare_dns_record" "www_cname" {
  zone_id = local.zone_id_pigeon_dev
  name    = "www"
  type    = "CNAME"
  content = "noisypigeon.github.io"
  proxied = false
  ttl     = 1
  comment = "github pages www cname"
}
