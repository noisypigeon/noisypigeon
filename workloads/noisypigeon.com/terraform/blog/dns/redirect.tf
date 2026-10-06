resource "cloudflare_ruleset" "www_to_apex" {
  zone_id = local.zone_id_noisypigeon_com
  name    = "www.noisypigeon.com to noisypigeon.com redirect"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules = [{
    expression  = "(http.host eq \"www.noisypigeon.com\")"
    description = "redirect www to the noisypigeon.com apex"
    action      = "redirect"
    action_parameters = {
      from_value = {
        status_code = 301
        target_url = {
          value = "https://noisypigeon.com"
        }
        preserve_query_string = true
      }
    }
  }]
}
