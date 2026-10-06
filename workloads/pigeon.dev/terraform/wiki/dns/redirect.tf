resource "cloudflare_ruleset" "www_to_apex" {
  zone_id = local.zone_id_pigeon_dev
  name    = "www.pigeon.dev to pigeon.dev redirect"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules = [{
    expression  = "(http.host eq \"www.pigeon.dev\")"
    description = "redirect www to the pigeon.dev apex"
    action      = "redirect"
    action_parameters = {
      from_value = {
        status_code = 301
        target_url = {
          value = "https://pigeon.dev"
        }
        preserve_query_string = true
      }
    }
  }]
}
