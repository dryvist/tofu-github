# Org-wide markdown linting, enforced as a Required Workflow.
#
# The moved block keeps the adopted live ruleset at its indexed address.
# `do_not_enforce_on_create` keeps brand-new repos from being blocked before
# their default branch exists. Enforcement defaults to `evaluate`; pass
# `-var markdown_lint_enforcement=active` to enforce.
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

# Org-wide repo-conventions presence check, enforced as a Required Workflow.
#
# Injects the org `.github` repo's conventions-check.yml (presence of LICENSE,
# AGENTS.md, a Nix dev-shell entry, and a release-please config) into every
# repo's default-branch PRs. Mirrors markdown_lint's shape.
#
# SOFT ROLLOUT: brand-new ruleset with no live import. Enforcement defaults to
# "evaluate" (reports in Rulesets > Insights without blocking), not "active",
# because many org repos currently lack AGENTS.md. The workflow also defaults
# to WARN (exit 0), so the check stays non-blocking on two independent levers
# until escalated. `do_not_enforce_on_create` keeps brand-new repos unblocked
# before their default branch exists. Enforce with:
# `tofu apply -var conventions_enforcement=active`.
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

# Org-wide AI review, enforced as a Required Workflow.
#
# Injects the org `.github` repo's ai-review.yml (PR-Agent against the model
# router) into every repo's pull requests so no repo skips an AI review by
# omitting a caller. Same shape as `conventions` above; enforcement is
# var.ai_review_enforcement (default evaluate — reviewed and reported, not
# gating; "active" gates the merge). `do_not_enforce_on_create` keeps
# brand-new repos unblocked before their default branch exists.
#
# Targets only the branches pull requests merge into: the default branch and
# main (git-flow repos default to develop). A required workflow behaves like a
# required status check on its target refs, so `~ALL` here would reject every
# push to an existing feature branch as "Required workflow not satisfied".
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

# Org-wide event forwarder, enforced as a Required Workflow.
#
# Attaches the selected owner's .github repo caller to every repository and
# branch. This rule is independently opt-in so existing workspace behavior is
# unchanged until event_forwarder_enabled is set.
resource "github_organization_ruleset" "event_forwarder" {
  count       = var.event_forwarder_enabled ? 1 : 0
  name        = "org-event-forwarder"
  target      = "branch"
  enforcement = var.event_forwarder_enforcement

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
        path          = ".github/workflows/github-event-forwarder.yml"
        ref           = "refs/heads/main"
      }
    }
  }

  bypass_actors {
    actor_type  = "OrganizationAdmin"
    bypass_mode = "pull_request"
  }
}

# Requires the disclosure workflow on public repository PRs targeting the
# default, main, and develop branches. `config/orgs/<owner>/required-workflows.yml` opts in each org.
resource "github_organization_ruleset" "disclosure_gate" {
  count       = try(local.required_workflows_config.disclosure_gate, false) ? 1 : 0
  name        = "org-disclosure-gate"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH", "refs/heads/main", "refs/heads/develop"]
      exclude = []
    }
    repository_property {
      include = [{
        name            = "visibility"
        property_values = ["public"]
        source          = "system"
      }]
    }
  }

  rules {
    required_workflows {
      do_not_enforce_on_create = true

      required_workflow {
        repository_id = module.repo_settings[".github"].repo_id
        path          = ".github/workflows/disclosure-gate.yml"
        ref           = "refs/heads/main"
      }
    }
  }
}

# Requires the main-source workflow on gitflow repositories' main PRs.
# `config/orgs/<owner>/required-workflows.yml` opts in each org.
resource "github_organization_ruleset" "main_source_gate" {
  count       = try(local.required_workflows_config.main_source_gate, false) ? 1 : 0
  name        = "org-main-source-gate"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/main"]
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
    required_workflows {
      do_not_enforce_on_create = true

      required_workflow {
        repository_id = module.repo_settings[".github"].repo_id
        path          = ".github/workflows/main-source-gate.yml"
        ref           = "refs/heads/main"
      }
    }
  }
}
