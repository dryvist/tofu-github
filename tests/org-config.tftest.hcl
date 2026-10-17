mock_provider "github" {
  mock_data "github_repository" {
    defaults = {
      default_branch = "main"
      full_name      = "JacobPEvans/.github"
      repo_id        = 1
      topics         = []
      visibility     = "public"
    }
  }

  mock_data "github_repositories" {
    defaults = {
      names = ["sample"]
    }
  }

  mock_data "github_actions_organization_variables" {
    defaults = {
      variables = []
    }
  }

  mock_data "github_repository_file" {
    defaults = {
      content = "[]"
    }
  }
}

mock_provider "vault" {}

run "empty_non_dryvist_config_plans_from_live_repo_data" {
  command = plan

  variables {
    github_owner                = "JacobPEvans"
    github_token_permission_set = "JacobPEvans-full-automation"
    automation_bypass_app_ids   = [1]
  }

  override_data {
    target = data.github_repositories.existing
    values = {
      names = []
    }
  }

  assert {
    condition     = local.org == "JacobPEvans"
    error_message = "The selected org must come from the workspace owner."
  }

  assert {
    condition     = length(local.repos) == 0 && length(local.ruleset_imports) == 0
    error_message = "An owner with no YAML overrides must use empty repo data and skip org-specific imports."
  }

  assert {
    condition     = length(local.merge_gate_contexts) == 0 && length(local.copilot_review_targets) == 0 && length(local.iac_drift.repos) == 0 && length(local.docs_publisher) == 0
    error_message = "Absent optional org files must disable their opt-in policies."
  }

  assert {
    condition     = !local.self_hosted_runners
    error_message = "An org without runner-group data must not create the public workflow runner role."
  }

  assert {
    condition     = length(local.managed_repos) == 1 && local.managed_repos["sample"].visibility == "public"
    error_message = "Repository metadata must be enumerated from GitHub when the org repo config is empty."
  }

  assert {
    condition     = length(module.repo_settings) == 1
    error_message = "Every repository found in the org must receive the shared repository settings module."
  }

  assert {
    condition     = local.gitflow_defaults.main_allowed_merge_methods == ["merge"] && local.gitflow_defaults.develop_allowed_merge_methods == ["squash"]
    error_message = "Git-flow main must remain merge-only and develop must be squash-only."
  }

  assert {
    condition     = local.actions_defaults.enabled_repositories == "all" && local.actions_defaults.allowed_actions == "all" && !local.actions_defaults.sha_pinning_required && local.actions_defaults.default_workflow_permissions == "read" && !local.actions_defaults.can_approve_pull_request_reviews
    error_message = "Shared Actions defaults must allow all actions, require no pinning, and use read-only workflow tokens without approval rights."
  }
}
