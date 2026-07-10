# Merge Gate as a required status check on main — every public repo.
#
# One org ruleset per live gate check-context (see config/merge-gate.yml for
# the context taxonomy and the freeze warning). Targets literal
# refs/heads/main on trunk AND git-flow repos alike: on trunk repos main is
# the default branch; on git-flow repos main is the release branch, and
# develop deliberately carries no required checks — a required status check
# blocks direct ref updates, and develop must keep accepting direct pushes
# and back-merges.
#
# strict policy is off: requiring branches to be up to date with main would
# serialize every merge behind a rebase, which the volume of Renovate PRs
# makes impractical.
resource "github_organization_ruleset" "org_merge_gate" {
  for_each = local.merge_gate_contexts

  name        = "org-merge-gate-${each.key}"
  target      = "branch"
  enforcement = var.org_merge_gate_enforcement

  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
    repository_name {
      include = each.value.repos
      exclude = []
    }
  }

  rules {
    required_status_checks {
      strict_required_status_checks_policy = false
      do_not_enforce_on_create             = true

      required_check {
        context = each.value.context
        # 15368 = the GitHub Actions app. Pinning the integration means no
        # other app can satisfy the context by posting a check with the same
        # name.
        integration_id = 15368
      }
    }
  }
}
