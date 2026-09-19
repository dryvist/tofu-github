# Merge Gate as a required status check on main and develop — every public repo.
#
# One org ruleset per live gate check-context (see config/merge-gate.yml for
# the context taxonomy and the freeze warning). Targets literal
# refs/heads/main and refs/heads/develop: on trunk repos only main exists; on
# git-flow repos main is the release branch and develop the integration
# branch. develop is included because org-gitflow-develop already requires a
# pull request there (direct pushes and back-merges arrive as PRs), so the
# only thing a required check changes on develop is that a PR can no longer
# merge while its gate is still queued or red.
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
      include = ["refs/heads/main", "refs/heads/develop"]
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
