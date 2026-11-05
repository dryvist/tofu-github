resource "github_organization_webhook" "hermes_pr_review" {
  count  = var.dryvist_org_extras && nonsensitive(var.hermes_webhook_url != "" && var.hermes_webhook_secret != "") ? 1 : 0
  events = ["pull_request"]

  configuration {
    url          = var.hermes_webhook_url
    content_type = "json"
    insecure_ssl = false
    secret       = var.hermes_webhook_secret
  }

  active = true
}

resource "github_organization_webhook" "event_queue" {
  count  = var.dryvist_org_extras && var.event_queue_webhook_enabled ? 1 : 0
  events = ["check_run", "pull_request"]

  configuration {
    url          = jsondecode(data.vault_kv_secret_v2.event_queue_intake_config[0].data_json).function_url
    content_type = "json"
    insecure_ssl = false
    secret       = jsondecode(data.vault_kv_secret_v2.event_queue_intake_secret[0].data_json).hmac_secret
  }

  active = true
}
