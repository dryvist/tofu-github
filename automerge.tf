# Auto-merge policy.
#
# Every repo carries the `automerge` custom property. It is required with the
# default "simple": a pull request may merge on its own (GitHub auto-merge,
# Renovate automerge, an automation app) once its required checks pass.
#
# config/automerge.yml names the "manual" repos, by name prefix or exact
# name. On those, the ruleset below requires one approving review on main and
# develop before a merge. People (org admins) and the agent apps in
# var.agent_bypass_app_ids bypass it on merge, so their pull requests merge as
# before. The bot-PR sweep's app (var.triage_merge_app_ids) also bypasses it;
# the sweep merges a dependency or release PR there only after the local
# triage agent labels it low risk. Other automation waits for a person.
locals {
  automerge_config = yamldecode(file("${path.module}/config/automerge.yml"))

  automerge_manual_repos = [
    for name in data.github_repositories.org.names : name
    if contains(local.automerge_config.manual.repos, name) ||
    anytrue([for p in local.automerge_config.manual.prefixes : startswith(name, p)])
  ]
}

resource "github_organization_custom_properties" "automerge" {
  property_name      = "automerge"
  value_type         = "single_select"
  required           = true
  default_value      = "simple"
  allowed_values     = ["simple", "manual"]
  values_editable_by = "org_actors"
}

resource "github_repository_custom_property" "automerge" {
  for_each = toset(local.automerge_manual_repos)

  repository     = each.value
  property_name  = github_organization_custom_properties.automerge.property_name
  property_type  = "single_select"
  property_value = ["manual"]
}

resource "github_organization_ruleset" "org_automerge_manual" {
  name        = "org-automerge-manual"
  target      = "branch"
  enforcement = var.org_automerge_manual_enforcement

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH", "refs/heads/main", "refs/heads/develop"]
      exclude = []
    }
    repository_property {
      include = [{
        name            = github_organization_custom_properties.automerge.property_name
        property_values = ["manual"]
        source          = "custom"
      }]
    }
  }

  rules {
    pull_request {
      required_approving_review_count   = 1
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = true
      required_review_thread_resolution = false
      allowed_merge_methods             = ["merge", "squash", "rebase"]
    }
  }

  # OrganizationAdmin is an ID-less actor type; the API ignores actor_id for it.
  bypass_actors {
    actor_type  = "OrganizationAdmin"
    bypass_mode = "pull_request"
  }

  dynamic "bypass_actors" {
    for_each = toset(concat(var.agent_bypass_app_ids, var.triage_merge_app_ids))
    content {
      actor_id    = bypass_actors.value
      actor_type  = "Integration"
      bypass_mode = "pull_request"
    }
  }
}

variable "org_automerge_manual_enforcement" {
  description = <<-EOT
    Enforcement mode for the ruleset on repos whose `automerge` property is
    "manual" (automerge.tf): one approving review on main and develop unless
    an org admin or an agent app in var.agent_bypass_app_ids merges.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_automerge_manual_enforcement)
    error_message = "org_automerge_manual_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "agent_bypass_app_ids" {
  description = <<-EOT
    GitHub App IDs of AI agents whose merges skip the approval that
    org-automerge-manual requires. Supplied as a workspace variable. List
    agent apps only, never dependency-update or release apps: a pull request
    from those must wait for a person on "manual" repos.
  EOT
  type        = list(number)
  default     = []
}

variable "triage_merge_app_ids" {
  description = <<-EOT
    GitHub App IDs that merge bot PRs on "manual" repos for the bot-PR sweep,
    which merges one only after the local triage agent labels it low risk.
    Their merges skip the approval org-automerge-manual requires. Supplied as
    a workspace variable.
  EOT
  type        = list(number)
  default     = []
}
