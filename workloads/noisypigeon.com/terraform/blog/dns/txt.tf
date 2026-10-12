# GitHub's domain-verification TXT record for noisypigeon.com, so the
# custom domain can't be claimed by a different GitHub account/repo (ADR-0158).
# In Terraform rather than a one-time manual click, per that ADR's decision.
#
# PLACEHOLDER CONTENT: GitHub only issues the real token once a human
# initiates "Add a domain" for noisypigeon.com under Settings > Pages >
# Verified domains on the noisypigeon account/org -- this value must be
# replaced with that real token before this resource is applied.
resource "cloudflare_dns_record" "github_pages_domain_verification" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "_github-pages-challenge-noisypigeon"
  type    = "TXT"
  content = "REPLACE_ME_WITH_GITHUB_DOMAIN_VERIFICATION_TOKEN"
  ttl     = 3600
}
