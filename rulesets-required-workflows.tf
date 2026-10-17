# Org-wide required-workflow rulesets.
resource "github_organization_ruleset" "markdown_lint" {
  count       = var.dryvist_org_extras ? 1 : 0
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
        repository_id = module.repo_settings[".github"].repo_id
        path          = ".github/workflows/markdownlint.yml"
        ref           = "refs/heads/main"
      }
    }
  }

  bypass_actors {
    actor_type  = "OrganizationAdmin"
    bypass_mode = "pull_request"
  }
}

moved {
  from = github_organization_ruleset.markdown_lint
  to   = github_organization_ruleset.markdown_lint[0]
}

resource "github_organization_ruleset" "conventions" {
  count       = var.dryvist_org_extras ? 1 : 0
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
        repository_id = module.repo_settings[".github"].repo_id
        path          = ".github/workflows/conventions-check.yml"
        ref           = "refs/heads/main"
      }
    }
  }

  bypass_actors {
    actor_type  = "OrganizationAdmin"
    bypass_mode = "pull_request"
  }
}

moved {
  from = github_organization_ruleset.conventions
  to   = github_organization_ruleset.conventions[0]
}

resource "github_organization_ruleset" "ai_review" {
  count       = var.dryvist_org_extras ? 1 : 0
  name        = "org-ai-review"
  target      = "branch"
  enforcement = var.ai_review_enforcement

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH", "refs/heads/main"]
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
        repository_id = module.repo_settings[".github"].repo_id
        path          = ".github/workflows/ai-review.yml"
        ref           = "refs/heads/main"
      }
    }
  }

  bypass_actors {
    actor_type  = "OrganizationAdmin"
    bypass_mode = "pull_request"
  }
}

moved {
  from = github_organization_ruleset.ai_review
  to   = github_organization_ruleset.ai_review[0]
}
