removed {
  from = github_organization_ruleset.docs_publisher

  lifecycle {
    destroy = false
  }
}

import {
  for_each = try(local.ruleset_imports.docs_publisher, null) == null ? {} : { existing = local.ruleset_imports.docs_publisher }
  to       = restapi_object.docs_publisher[0]
  id       = "/orgs/${var.github_owner}/rulesets/${each.value}"
}

resource "restapi_object" "docs_publisher" {
  count        = try(local.docs_publisher.repository, null) == null ? 0 : 1
  path         = "/orgs/${var.github_owner}/rulesets"
  id_attribute = "id"
  # Fields GitHub adds to a ruleset response; they never appear in the request body.
  ignore_changes_to = ["_links", "created_at", "id", "node_id", "source", "source_type", "updated_at"]

  data = jsonencode({
    name        = "docs-publisher"
    target      = "branch"
    enforcement = var.docs_publisher_enforcement
    conditions = {
      ref_name = {
        include = ["refs/heads/main"]
        exclude = []
      }
      repository_name = {
        include = [local.docs_publisher.repository]
        exclude = []
      }
    }
    rules = [{
      type = "pull_request"
      parameters = merge(local.pull_request_rule_base, {
        required_approving_review_count   = local.docs_publisher.pull_request.required_approvals
        dismiss_stale_reviews_on_push     = true
        require_code_owner_review         = false
        require_last_push_approval        = true
        required_review_thread_resolution = true
        allowed_merge_methods             = local.docs_publisher.pull_request.allowed_merge_methods
      })
    }]
    bypass_actors = [
      for actor_id in toset(concat(try(local.automerge_config.triage_merge_app_ids, []), local.release_app_ids)) : {
        actor_id    = actor_id
        actor_type  = "Integration"
        bypass_mode = "pull_request"
      }
    ]
  })
}

# Org custom property classifying each repo's documentation as private (the
# default) or public. Required with a default, so a repo that never sets it
# still reads as private. require_explicit_values must stay off: with it on,
# GitHub refuses to create any repo that does not name a value, which breaks
# every module.repo_settings create. The provider has no attribute for that
# flag and omits it on write, which resets it to off.
resource "github_organization_custom_properties" "docs" {
  property_name      = "docs"
  value_type         = "single_select"
  required           = true
  default_value      = "private"
  allowed_values     = ["private", "public"]
  values_editable_by = "org_and_repo_actors"
}
