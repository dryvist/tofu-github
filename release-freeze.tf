# Git-flow `develop` release-freeze status.
#
# The shared status workflow posts `release-freeze`; evaluate mode reports the
# requirement without blocking merges until every git-flow repo calls it.
resource "github_organization_ruleset" "org_release_freeze" {
  count       = var.dryvist_org_extras ? 1 : 0
  name        = "org-release-freeze"
  target      = "branch"
  enforcement = var.org_release_freeze_enforcement

  conditions {
    ref_name {
      include = ["refs/heads/develop"]
      exclude = []
    }
    repository_property {
      include = [{
        name            = "gitflow"
        property_values = ["true"]
        source          = "custom"
      }]
    }
  }

  rules {
    required_status_checks {
      strict_required_status_checks_policy = false
      do_not_enforce_on_create             = true

      required_check {
        context = "release-freeze"
      }
    }
  }
}

moved {
  from = github_organization_ruleset.org_release_freeze
  to   = github_organization_ruleset.org_release_freeze[0]
}
