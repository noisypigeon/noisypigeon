resource "cloudflare_dns_record" "did" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "_atproto"
  type    = "TXT"
  content = "did=did:plc:kkh3qo4rjs4b6aayzj4fcpkg"
  ttl     = 1
  comment = "bluesky domain handle"
}
