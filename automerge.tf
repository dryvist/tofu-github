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
  automerge_manual_repos = [
    for name in data.github_repositories.org.names : name
    if contains(try(local.automerge_config.manual.repos, []), name) ||
    anytrue([for p in try(local.automerge_config.manual.prefixes, []) : startswith(name, p)])
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

removed {
  from = github_organization_ruleset.org_automerge_manual

  lifecycle {
    destroy = false
  }
}

import {
  for_each = try(local.ruleset_imports.org_automerge_manual, null) == null ? {} : { existing = local.ruleset_imports.org_automerge_manual }
  to       = restapi_object.org_automerge_manual
  id       = "/orgs/${var.github_owner}/rulesets/${each.value}"
}

resource "restapi_object" "org_automerge_manual" {
  path         = "/orgs/${var.github_owner}/rulesets"
  id_attribute = "id"
  # Fields GitHub adds to a ruleset response; they never appear in the request body.
  ignore_changes_to = ["_links", "created_at", "id", "node_id", "source", "source_type", "updated_at"]

  data = jsonencode({
    name        = "org-automerge-manual"
    target      = "branch"
    enforcement = var.org_automerge_manual_enforcement
    conditions = {
      ref_name = {
        include = ["~DEFAULT_BRANCH", "refs/heads/main", "refs/heads/develop"]
        exclude = []
      }
      repository_property = {
        include = [{
          name            = github_organization_custom_properties.automerge.property_name
          property_values = ["manual"]
          source          = "custom"
        }]
        exclude = []
      }
    }
    rules = [{
      type = "pull_request"
      parameters = merge(local.pull_request_rule_base, {
        required_approving_review_count   = 0
        dismiss_stale_reviews_on_push     = true
        require_code_owner_review         = false
        require_last_push_approval        = false
        required_review_thread_resolution = false
        allowed_merge_methods             = ["merge", "squash", "rebase"]
      })
    }]
    # OrganizationAdmin has no actor_id. The tuple keeps its object without an actor_id key.
    bypass_actors = concat(
      [{ actor_type = "OrganizationAdmin", bypass_mode = "pull_request" }],
      [for actor_id in toset(concat(
        try(local.automerge_config.agent_bypass_app_ids, []),
        try(local.automerge_config.triage_merge_app_ids, []),
        local.release_app_ids,
      )) : { actor_id = actor_id, actor_type = "Integration", bypass_mode = "pull_request" }],
    )
  })
}
