resource "github_organization_ruleset" "docs_publisher" {
  count       = try(local.docs_publisher.repository, null) == null ? 0 : 1
  name        = "docs-publisher"
  target      = "branch"
  enforcement = var.docs_publisher_enforcement

  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
    repository_name {
      include = [local.docs_publisher.repository]
      exclude = []
    }
  }

  rules {
    pull_request {
      required_approving_review_count   = local.docs_publisher.pull_request.required_approvals
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = true
      required_review_thread_resolution = true
      allowed_merge_methods             = local.docs_publisher.pull_request.allowed_merge_methods
    }
  }

  dynamic "bypass_actors" {
    for_each = toset(concat(var.triage_merge_app_ids, local.release_app_ids))
    content {
      actor_id    = bypass_actors.value
      actor_type  = "Integration"
      bypass_mode = "pull_request"
    }
  }
}

moved {
  from = github_organization_ruleset.docs_publisher
  to   = github_organization_ruleset.docs_publisher[0]
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
