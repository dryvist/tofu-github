# Auto-merge policy.
#
# Every repo carries the `automerge` custom property. It is required with the
# default "simple": a pull request may merge on its own (GitHub auto-merge,
# Renovate automerge, an automation app) once its required checks pass.
#
# A repo opts out with `automerge: manual` in config/repos.yml. The ruleset
# below then requires one approving review on main and develop, with the
# approval given after the last push. No bypass actors are listed, so no app
# or automation can merge there without a person.
locals {
  automerge_manual_repos = [for name, cfg in local.repos : name if try(cfg.automerge, "simple") == "manual"]
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
}
