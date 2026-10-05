resource "cloudflare_ruleset" "to_noisypigeon_com" {
  zone_id = local.zone_id_pigeon_dev
  name    = "pigeon.dev to noisypigeon.com redirect"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules = [{
    expression  = "(http.host eq \"pigeon.dev\") or (http.host eq \"www.pigeon.dev\")"
    description = "redirect pigeon.dev and www to the noisypigeon.com homepage"
    action      = "redirect"
    action_parameters = {
      from_value = {
        status_code = 302
        target_url = {
          value = "https://noisypigeon.com"
        }
        preserve_query_string = false
      }
    }
  }]
}
