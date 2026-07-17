# Copilot code review -- narrowly targeted pilot, bound to explicit
# (branch, repo-list) pairs from config/copilot-review.yml, NOT a property
# match against every gitflow repo. The org has already exhausted its
# Copilot review capacity once from unrelated usage, and each review bills
# AI credits directly with no pooled seat allowance -- growing this pilot
# is a one-line YAML edit, never a broader property match.
# review_on_push = false caps spend at ~1 review per PR regardless of push
# count.
resource "github_organization_ruleset" "org_copilot_review" {
  for_each = local.copilot_review_targets

  name        = "org-copilot-review-${each.key}"
  target      = "branch"
  enforcement = var.org_copilot_review_enforcement

  conditions {
    ref_name {
      include = ["refs/heads/${each.key}"]
      exclude = []
    }
    repository_name {
      include = each.value
      exclude = []
    }
  }

  rules {
    copilot_code_review {
      review_on_push             = false
      review_draft_pull_requests = false
    }
  }
}
