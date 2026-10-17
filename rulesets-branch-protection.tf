# Org-wide branch-protection — quality rules on the default branch of every
# repo not covered by the git-flow rulesets.
#
# Reverse-engineered from the pre-Terraform "main" org ruleset plus new
# directives: Conventional Commits enforcement and PR
# thread resolution. No bypass actors: rules apply to everyone including
# org admins, so an admin's own commits are still signed and
# Conventional-format. A separate imported ruleset below extends signature
# enforcement to every branch. Review-count enforcement lives in a separate
# ruleset (org_review_gate) so admin bypass on review doesn't accidentally
# weaken these quality gates.
#
# Import-on-first-apply: the import block below adopts the live ruleset
# into Terraform state so apply reconciles instead of creating a duplicate.
# Only the existing flat-config workspace adopts this organization-specific ID.
import {
  for_each = try(local.ruleset_imports.org_branch_protection, null) == null ? {} : { existing = local.ruleset_imports.org_branch_protection }
  to       = restapi_object.org_branch_protection
  id       = "/orgs/${var.github_owner}/rulesets/${each.value}"
}

removed {
  from = github_organization_ruleset.org_branch_protection

  lifecycle {
    destroy = false
  }
}

resource "restapi_object" "org_branch_protection" {
  path         = "/orgs/${var.github_owner}/rulesets"
  id_attribute = "id"
  # Fields GitHub adds to a ruleset response; they never appear in the request body.
  ignore_changes_to = ["_links", "created_at", "id", "node_id", "source", "source_type", "updated_at"]

  data = jsonencode({
    name          = "org-branch-protection"
    target        = "branch"
    enforcement   = var.org_branch_protection_enforcement
    bypass_actors = []
    conditions = {
      ref_name = {
        include = ["~DEFAULT_BRANCH"]
        exclude = []
      }
      # Git-flow repos are excluded: their default branch is develop. Their main and
      # develop protection comes from the org-gitflow-* rulesets below instead.
      # Upstream forks are excluded: upstream history cannot satisfy the signature
      # and commit-format rules. org-upstream-fork-protection (upstream-forks.tf)
      # covers their default branch instead.
      repository_property = {
        include = []
        exclude = [
          {
            name            = "gitflow"
            property_values = ["true"]
            source          = "custom"
          },
          {
            name            = github_organization_custom_properties.upstream_fork.property_name
            property_values = ["true"]
            source          = "custom"
          },
        ]
      }
    }
    rules = [
      { type = "required_signatures" },
      {
        type = "branch_name_pattern"
        parameters = {
          operator = local.branch_protection_defaults.branch_name_operator
          pattern  = local.branch_protection_defaults.branch_name_pattern
          negate   = false
          name     = ""
        }
      },
      {
        type = "pull_request"
        parameters = merge(local.pull_request_rule_base, {
          required_approving_review_count   = 0
          dismiss_stale_reviews_on_push     = false
          require_code_owner_review         = false
          require_last_push_approval        = false
          required_review_thread_resolution = true
          allowed_merge_methods             = local.branch_protection_defaults.allowed_merge_methods
        })
      },
      {
        type = "commit_message_pattern"
        parameters = {
          name     = "conventional-commits"
          operator = "regex"
          pattern  = local.commit_message_pattern
          negate   = false
        }
      },
      { type = "deletion" },
      { type = "non_fast_forward" },
    ]
  })
}

# Org-wide signature enforcement on every branch.
#
# This ruleset already exists live and is adopted. Keeping it separate from
# default-branch protection preserves the broader all-branch coverage. Upstream
# forks are the one exclusion: their upstream history is unsigned by
# construction, so no sync could ever land.
# Only the existing flat-config workspace adopts this organization-specific ID.
import {
  for_each = try(local.ruleset_imports.required_signatures, null) == null ? {} : { existing = local.ruleset_imports.required_signatures }
  to       = github_organization_ruleset.required_signatures
  id       = each.value
}

resource "github_organization_ruleset" "required_signatures" {
  name        = "required_signatures"
  target      = "branch"
  enforcement = var.required_signatures_enforcement

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = []
    }
    repository_property {
      exclude = [{
        name            = github_organization_custom_properties.upstream_fork.property_name
        property_values = ["true"]
        source          = "custom"
      }]
    }
  }

  rules {
    required_signatures = true
  }
}

# Commit subjects on every non-default branch, so a bad subject is refused at
# push rather than at merge. Merge messages pass (branch syncs, git-flow main);
# default branches keep their own stricter rules above.
resource "github_organization_ruleset" "commit_subject_branches" {
  name        = "org-commit-subject-branches"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = ["~DEFAULT_BRANCH"]
    }
    repository_property {
      exclude = [{
        name            = github_organization_custom_properties.upstream_fork.property_name
        property_values = ["true"]
        source          = "custom"
      }]
    }
  }

  rules {
    commit_message_pattern {
      name     = "conventional-commits-or-merge"
      operator = "regex"
      pattern  = local.gitflow_commit_message_pattern
      negate   = false
    }
  }
}

# Org-wide review gate — resolved review threads on PRs, no required approval.
#
# Separate ruleset (rather than rolled into org_branch_protection) so the
# bypass actors below apply ONLY to review enforcement, not
# to signed commits or commit format. It requires no approving or CODEOWNER
# review; enabling it adds only the thread-resolution rule.
#
# bypass_mode = "pull_request": admins bypass on merge only, not on push.
# Pushes still satisfy every other rule (signed, conventional).
# Granting an additional account the OrganizationAdmin role extends this
# bypass to them — review the role assignments before adding admins.
removed {
  from = github_organization_ruleset.org_review_gate

  lifecycle {
    destroy = false
  }
}

import {
  for_each = try(local.ruleset_imports.org_review_gate, null) == null ? {} : { existing = local.ruleset_imports.org_review_gate }
  to       = restapi_object.org_review_gate
  id       = "/orgs/${var.github_owner}/rulesets/${each.value}"
}

resource "restapi_object" "org_review_gate" {
  path         = "/orgs/${var.github_owner}/rulesets"
  id_attribute = "id"
  # Fields GitHub adds to a ruleset response; they never appear in the request body.
  ignore_changes_to = ["_links", "created_at", "id", "node_id", "source", "source_type", "updated_at"]

  data = jsonencode({
    name        = "org-review-gate"
    target      = "branch"
    enforcement = var.org_review_gate_enforcement
    conditions = {
      ref_name = {
        include = ["~DEFAULT_BRANCH"]
        exclude = []
      }
      # Git-flow repos are excluded so the review gate never binds develop (their
      # default branch), where direct pushes and back-merges must flow freely.
      # A gated main on a git-flow repo would be re-added by an org-gitflow-main
      # variant if/when this ruleset is enabled — today it is disabled by default.
      repository_property = {
        include = []
        exclude = [{
          name            = "gitflow"
          property_values = ["true"]
          source          = "custom"
        }]
      }
    }
    rules = [{
      type = "pull_request"
      parameters = merge(local.pull_request_rule_base, {
        required_approving_review_count   = 0
        dismiss_stale_reviews_on_push     = false
        require_code_owner_review         = false
        require_last_push_approval        = false
        required_review_thread_resolution = true
        allowed_merge_methods             = local.branch_protection_defaults.allowed_merge_methods
      })
    }]
    # OrganizationAdmin is an ID-less actor type: the API reads actor_id back as null.
    bypass_actors = concat(
      [{ actor_id = null, actor_type = "OrganizationAdmin", bypass_mode = "pull_request" }],
      [for actor_id in toset(local.release_app_ids) : { actor_id = actor_id, actor_type = "Integration", bypass_mode = "pull_request" }],
    )
  })
}
