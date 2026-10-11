# Org-wide branch-write restriction — every branch except main.
#
# Only the automation apps in var.automation_bypass_app_ids may create or update
# a branch other than main. Every other actor, org admins included, cannot push,
# create or update such a branch. Merging a pull request into main stays open to
# anyone the other rulesets allow, because main is excluded from this ruleset.
# On git-flow repos that leaves develop covered: only the apps merge into it.
#
# Pushes to the PR branch, the web-UI "Update branch" button, and in-browser
# edits that open a branch all count as creates or updates, so those paths are
# closed to non-bypass actors too.
#
# This ruleset adds no review requirement. Required reviews, signatures, commit
# format and the Merge Gate stay in the rulesets above and in merge-gate.tf.
resource "github_organization_ruleset" "org_branch_write_restriction" {
  name        = "org-branch-write-restriction"
  target      = "branch"
  enforcement = var.org_branch_write_restriction_enforcement

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = ["refs/heads/main"]
    }
    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    creation = true
    update   = true
  }

  dynamic "bypass_actors" {
    for_each = toset(var.automation_bypass_app_ids)
    content {
      actor_id    = bypass_actors.value
      actor_type  = "Integration"
      bypass_mode = "always"
    }
  }
}
