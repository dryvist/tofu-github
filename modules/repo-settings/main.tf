# Per-repo settings — the repository-settings half of the retired
# `.github-tofu` nix-repo module. Baseline established on the nix-* family:
# squash + rebase merges only (no merge commit), auto-merge on, branch deleted
# on merge, web commit signoff required, wiki off.
#
# Per-repo rulesets are intentionally NOT ported: the org-level rulesets in
# ../../rulesets.tf already enforce signed commits, linear history, and
# Conventional Commits on every repo. Porting the source module's per-repo
# `all` ruleset would duplicate that org-level coverage.
#
# The owner is supplied by the calling module's provider (a single
# org-scoped provider at the root); this module never names it.

resource "github_repository" "this" {
  # checkov:skip=CKV_GIT_1: These repos are intentionally public. The org cost
  # policy (see AGENTS.md) depends on public visibility to keep secret scanning
  # free; forcing private would invert the design and incur GHAS charges. The
  # visibility variable is validated and per-repo in config/repos.yml.
  # checkov:skip=CKV2_GIT_1: Branch protection is associated at the ORG level via
  # the github_organization_ruleset resources in ../../rulesets.tf (signed
  # commits, linear history, Conventional Commits on every repo's default
  # branch). Checkov only detects per-repo branch_protection resources, not the
  # org rulesets that cover these repos — so this is a false negative for it.
  name        = var.name
  description = var.description
  topics      = var.topics

  visibility = var.visibility
  archived   = var.archived

  has_issues      = true
  has_wiki        = false
  has_projects    = true
  has_discussions = false

  allow_squash_merge          = true
  allow_merge_commit          = false
  allow_rebase_merge          = true
  allow_auto_merge            = true
  delete_branch_on_merge      = true
  web_commit_signoff_required = true

  # Secret scanning + push protection are free on public repos but require
  # paid GitHub Advanced Security (Secret Protection) on private repos. Emit
  # the security_and_analysis block ONLY for public repos so an apply can never
  # silently enable a paid feature on a private repo. The source module
  # hardcoded visibility = "public" and enabled these unconditionally — that
  # would charge GHAS the moment a private repo entered the inventory.
  dynamic "security_and_analysis" {
    for_each = var.visibility == "public" ? [1] : []

    content {
      secret_scanning {
        status = "enabled"
      }
      secret_scanning_push_protection {
        status = "enabled"
      }
    }
  }

  # Prevent TF from recreating or renaming existing repos on first apply.
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      # Auto-init only matters at creation; ignore so imports don't churn.
      auto_init,
      gitignore_template,
      license_template,
      # Homepage URL is per-repo and may be set manually; don't fight it.
      homepage_url,
    ]
  }
}

# Dependabot alerts — notifications when CVEs are detected in dependencies.
# Free on public and private repos (dependency graph + Dependabot is not GHAS).
resource "github_repository_vulnerability_alerts" "this" {
  repository = github_repository.this.name
}

# Dependabot automatic security update PRs. Also free on public and private.
resource "github_repository_dependabot_security_updates" "this" {
  repository = github_repository.this.name
  enabled    = true
  depends_on = [github_repository_vulnerability_alerts.this]
}
