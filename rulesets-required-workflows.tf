# Org-wide markdown linting, enforced as a Required Workflow.
#
# Adopts the existing disabled live ruleset so apply reconciles instead of
# creating a duplicate. `do_not_enforce_on_create` keeps brand-new repos from
# being blocked before their default branch exists. Enforcement defaults to
# the legacy `evaluate` posture; pass `-var markdown_lint_enforcement=active`
# to enforce.
import {
  to = github_organization_ruleset.markdown_lint
  id = local.ruleset_imports.markdown_lint
}

resource "github_organization_ruleset" "markdown_lint" {
  name        = "org-markdown-lint"
  target      = "branch"
  enforcement = var.markdown_lint_enforcement

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = []
    }
    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    required_workflows {
      do_not_enforce_on_create = true

      required_workflow {
        repository_id = data.github_repository.dot_github.repo_id
        path          = ".github/workflows/markdownlint.yml"
        ref           = "refs/heads/main"
      }
    }
  }
}

# Org-wide repo-conventions presence check, enforced as a Required Workflow.
#
# Injects the org `.github` repo's conventions-check.yml (presence of LICENSE,
# AGENTS.md, a Nix dev-shell entry, and a release-please config) into every
# repo's default-branch PRs. Mirrors markdown_lint's shape.
#
# SOFT ROLLOUT: this is a brand-new ruleset (no live import) and its
# enforcement defaults to "evaluate" (dry-run — reports in Rulesets > Insights
# without blocking merges), not the "active" default used for other new
# rulesets, because a large share of org repos currently lack AGENTS.md. The
# workflow itself also defaults to WARN (exit 0), so the check stays
# non-blocking on two independent levers until deliberately escalated.
# `do_not_enforce_on_create` keeps brand-new repos from being blocked before
# their default branch exists. Enforce with:
# `tofu apply -var conventions_enforcement=active`.
resource "github_organization_ruleset" "conventions" {
  name        = "org-conventions"
  target      = "branch"
  enforcement = var.conventions_enforcement

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = []
    }
    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    required_workflows {
      do_not_enforce_on_create = true

      required_workflow {
        repository_id = data.github_repository.dot_github.repo_id
        path          = ".github/workflows/conventions-check.yml"
        ref           = "refs/heads/main"
      }
    }
  }
}
