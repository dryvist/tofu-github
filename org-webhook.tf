resource "github_organization_webhook" "hermes_pr_review" {
  count  = nonsensitive(var.hermes_webhook_url != "" && var.hermes_webhook_secret != "") ? 1 : 0
  events = ["pull_request"]

  configuration {
    url          = var.hermes_webhook_url
    content_type = "json"
    insecure_ssl = false
    secret       = var.hermes_webhook_secret
  }

  active = true
}
