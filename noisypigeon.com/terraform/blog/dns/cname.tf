# DNS records to point noisypigeon.com (apex + www) at GitHub Pages
# (noisypigeon.github.io) -- ADR-0158 cuts the site back over from the
# Scaleway bucket this leaf used to front. Both DNS-only (proxied = false),
# restoring the pre-ADR-0132 shape exactly: GitHub Pages issues its own
# Let's Encrypt certificate for the custom domain, which it cannot do while
# Cloudflare is proxying (and terminating TLS for) the apex, and it
# redirects www -> apex natively, so no separate redirect rule is needed
# here (mirrors pigeon.dev/terraform/wiki/dns/cname.tf, ADR-0156).

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

# Was placeholder_www (a Cloudflare-proxied CNAME to the apex, backing
# redirect.tf's ruleset) -- renaming in place via `moved` so this becomes an
# in-place attribute update, not a destroy+recreate (same resource ID
# throughout, mirroring ADR-0132's own `terraform state mv` for the reverse
# direction).
moved {
  from = cloudflare_dns_record.placeholder_www
  to   = cloudflare_dns_record.www_cname
}
