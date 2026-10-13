resource "cloudflare_ruleset" "to_noisypigeon_com" {
  zone_id = local.zone_id_willowgraysen_com
  name    = "willowgraysen.com to noisypigeon.com redirect"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules = [{
    expression  = "(http.host eq \"willowgraysen.com\") or (http.host eq \"www.willowgraysen.com\")"
    description = "redirect willowgraysen.com and www to the noisypigeon.com homepage"
    action      = "redirect"
    action_parameters = {
      from_value = {
        status_code = 301
        target_url = {
          value = "https://noisypigeon.com"
        }
        preserve_query_string = false
      }
    }
  }]
}
