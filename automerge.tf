# Auto-merge policy.
#
# Every repo carries the `automerge` custom property. It is required with the
# default "simple": a pull request may merge on its own (GitHub auto-merge,
# Renovate automerge, an automation app) once its required checks pass.
#
# The selected per-org automerge.yml names the "manual" repos, by name prefix
# or exact name. On those, the ruleset below requires one approving review on
# main and develop before a merge. Org admins, configured agent apps, the
# release automation app from GH_ACTION_RELEASE_PLEASE_APP_ID, and the bot-PR
# sweep app bypass the approval on merge. The sweep merges bot PRs only after the local
# triage agent labels them low risk. Required status checks still apply to every
# merge.
locals {
  automerge_config = yamldecode(file("${path.module}/${local.org_config_dir}/automerge.yml"))

  # Agent apps that always bypass the review on "manual" repos: jacobpevans-claude
  # and JacobPEvans-claude-admin. Committed so an empty workspace variable cannot
  # drop them.
  automerge_agent_app_ids = [2956476, 5274352]

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
    for_each = toset(concat(local.automerge_agent_app_ids, var.agent_bypass_app_ids, var.triage_merge_app_ids, local.release_app_ids))
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
    "manual" (automerge.tf): one approving review on main and develop.
    OrganizationAdmin, configured agent apps, triage apps, and the release
    automation app can bypass the review when merging.
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
    org-automerge-manual requires, in addition to local.automerge_agent_app_ids.
    The default mirrors the workspace variable. The release automation app is
    handled by its own bypass entry from GH_ACTION_RELEASE_PLEASE_APP_ID.
    Dependency-update apps use the triage path and do not get a direct bypass.
  EOT
  type        = list(number)
  default     = [2956476, 1236702, 4241562, 4952939, 1144995, 1210556, 5274352]
}

variable "triage_merge_app_ids" {
  description = <<-EOT
    GitHub App IDs that merge bot PRs on "manual" repos for the bot-PR sweep,
    which merges one only after the local triage agent labels it low risk.
    Their merges skip the approval org-automerge-manual requires. The default
    mirrors the workspace variable.
  EOT
  type        = list(number)
  default     = [3923580]
}
