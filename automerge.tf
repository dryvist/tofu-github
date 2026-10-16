# Auto-merge policy.
#
# Every repo carries the `automerge` custom property. It is required with the
# default "simple": a pull request may merge on its own (GitHub auto-merge,
# Renovate automerge, an automation app) once its required checks pass.
#
# The selected per-org automerge.yml names the "manual" repos, by name prefix
# or exact name. The ruleset below requires no approving review: required
# status checks are the only merge gate on every repo.
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
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = false
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
