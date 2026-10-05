resource "cloudflare_dns_record" "dkim_fm1" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "fm1._domainkey"
  type    = "CNAME"
  content = "fm1.noisypigeon.com.dkim.fmhosted.com"
  ttl     = 1
  proxied = false
  comment = "fastmail primary dkim"
}

resource "cloudflare_dns_record" "dkim_fm2" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "fm2._domainkey"
  type    = "CNAME"
  content = "fm2.noisypigeon.com.dkim.fmhosted.com"
  ttl     = 1
  proxied = false
  comment = "fastmail secondary dkim"
}

resource "cloudflare_dns_record" "dkim_fm3" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "fm3._domainkey"
  type    = "CNAME"
  content = "fm3.noisypigeon.com.dkim.fmhosted.com"
  ttl     = 1
  proxied = false
  comment = "fastmail tertiary dkim"
}
