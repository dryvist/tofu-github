# Org-level webhook that sends pull_request events to the Hermes PR-review
# intake. Created only when both variables are set.
variable "hermes_webhook_url" {
  description = "Hermes PR-review intake endpoint. Empty skips the webhook."
  type        = string
  sensitive   = true
  default     = ""
}

variable "hermes_webhook_secret" {
  description = "HMAC secret GitHub signs deliveries with (X-Hub-Signature-256). Empty skips the webhook."
  type        = string
  sensitive   = true
  default     = ""
}

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
