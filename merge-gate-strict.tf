# Strict up-to-date policy on the merge gate checks.
#
# Targets the same refs, repos and contexts as org_merge_gate (merge-gate.tf),
# which leaves strict off. A pull request on those refs must be current with
# its base branch before it merges, except for the apps in the bypass list.
# Those apps still face the gate check through org_merge_gate, whose only
# bypass is OrganizationAdmin.
data "github_app" "renovate" {
  slug = "renovate"
}

resource "github_organization_ruleset" "org_merge_gate_strict" {
  for_each = var.dryvist_org_extras ? local.merge_gate_contexts : {}

  name        = "org-merge-gate-strict-${each.key}"
  target      = "branch"
  enforcement = var.merge_gate_strict_enforcement

  lifecycle {
    # Private repos reach the gate only through the private overrides; without them a plan would drop those repos.
    precondition {
      condition     = !local.merge_gate_requires_private_repos || length(local.private_merge_gate_entries) > 0
      error_message = "This org's merge gates require private repo overrides, and none were supplied."
    }
  }

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
      strict_required_status_checks_policy = true
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

  bypass_actors {
    actor_type  = "OrganizationAdmin"
    bypass_mode = "pull_request"
  }

  # AI-agent apps (agent_bypass_app_ids in automerge.yml) are deliberately absent from this list.
  dynamic "bypass_actors" {
    for_each = toset(concat(
      try(local.automerge_config.triage_merge_app_ids, []),
      local.release_app_ids,
      [tonumber(data.github_app.renovate.id)],
    ))

    content {
      actor_id    = bypass_actors.value
      actor_type  = "Integration"
      bypass_mode = "pull_request"
    }
  }
}
