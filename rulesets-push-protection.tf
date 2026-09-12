# Org-wide native push protection — max file size + banned extensions.
#
# Enforced at the git layer by GitHub's own push rules; no workflow runs.
# Thresholds and extension list come from config/rulesets-defaults.yml via
# local.push_protection_defaults, so this resource carries no magic numbers
# or hardcoded lists. Bypass actors are managed in the GitHub UI — this
# resource does not claim ownership of them, so manual exemptions for
# specific repos or actors persist across applies.
resource "github_organization_ruleset" "org_push_protection" {
  name        = "org-push-protection"
  target      = "push"
  enforcement = var.org_push_protection_enforcement

  conditions {
    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    max_file_size {
      max_file_size = local.push_protection_defaults.max_file_size_mb
    }

    file_extension_restriction {
      restricted_file_extensions = local.push_protection_defaults.banned_file_extensions
    }
  }
}
