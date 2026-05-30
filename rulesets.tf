# Org-wide markdown linting, enforced as a Required Workflow.
#
# Every repo's default-branch PRs must pass the markdownlint workflow that
# lives in the org's `.github` repo (resolved at apply time via
# data.github_repository.dot_github). One workflow + one config — no
# per-repo markdownlint files to drift, no per-repo `uses:` wiring.
resource "github_organization_ruleset" "markdown_lint" {
  name        = "org-markdown-lint"
  target      = "branch"
  enforcement = var.markdown_lint_enforcement

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    required_workflows {
      required_workflow {
        repository_id = data.github_repository.dot_github.repo_id
        path          = ".github/workflows/markdownlint.yml"
        ref           = "refs/heads/main"
      }
    }
  }
}
