# Org-wide markdown linting, enforced as a Required Workflow.
#
# Every repo's default-branch PRs must pass dryvist/.github's markdownlint
# workflow. The rule references ONE workflow + ONE config (both in
# dryvist/.github), so there are no per-repo markdownlint files to drift —
# this is the org-native replacement for per-repo `uses:` wiring.
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
        repository_id = var.dot_github_repository_id
        path          = ".github/workflows/markdownlint.yml"
        ref           = "refs/heads/main"
      }
    }
  }
}
