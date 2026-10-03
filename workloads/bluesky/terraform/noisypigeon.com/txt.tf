resource "cloudflare_dns_record" "did" {
  zone_id = local.cloudflare_noisypigeon_com_zone_id
  name    = "_atproto"
  type    = "TXT"
  content = "did=did:plc:kkh3qo4rjs4b6aayzj4fcpkg"
  ttl     = 1
  comment = "bluesky domain handle"
}
