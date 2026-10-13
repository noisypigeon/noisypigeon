resource "cloudflare_dns_record" "dmarc" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "_dmarc"
  type    = "TXT"
  content = "v=DMARC1; p=quarantine; pct=100; adkim=s; aspf=s"
  ttl     = 1
  comment = "proton spf verification"
}
