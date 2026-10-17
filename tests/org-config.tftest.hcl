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

  mock_data "github_branch" {
    defaults = {
      sha = "test-commit"
    }
  }

  mock_data "github_tree" {
    defaults = {
      entries = []
    }
  }
}

mock_provider "vault" {}

mock_provider "restapi" {}

run "empty_non_dryvist_config_plans_from_live_repo_data" {
  command = plan

  variables {
    github_owner              = "JacobPEvans"
    automation_bypass_app_ids = [1]
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
    condition     = length(local.managed_repos) == 2 && local.managed_repos[".github"].visibility == "public" && local.managed_repos["sample"].visibility == "public"
    error_message = "Repository metadata must be enumerated from GitHub when the org repo config is empty."
  }

  assert {
    condition     = length(module.repo_settings) == 2
    error_message = "Every repository found in the org must receive the shared repository settings module."
  }

  assert {
    condition     = local.gitflow_defaults.main_allowed_merge_methods == ["merge"] && local.gitflow_defaults.develop_allowed_merge_methods == ["merge", "squash", "rebase"]
    error_message = "Git-flow main must remain merge-only and develop must allow merge, squash and rebase."
  }

  assert {
    condition     = local.actions_defaults.enabled_repositories == "all" && local.actions_defaults.allowed_actions == "all" && !local.actions_defaults.sha_pinning_required && local.actions_defaults.default_workflow_permissions == "read" && !local.actions_defaults.can_approve_pull_request_reviews
    error_message = "Shared Actions defaults must allow all actions, require no pinning, and use read-only workflow tokens without approval rights."
  }

  assert {
    condition = alltrue([
      for ruleset in concat([
        jsondecode(restapi_object.org_branch_protection.data),
        jsondecode(restapi_object.org_review_gate.data),
        jsondecode(restapi_object.org_gitflow_main.data),
        jsondecode(restapi_object.org_gitflow_develop.data),
        jsondecode(restapi_object.org_automerge_manual.data),
        jsondecode(restapi_object.org_upstream_fork_protection[0].data),
      ], [for docs in restapi_object.docs_publisher : jsondecode(docs.data)]) : length([for rule in ruleset.rules : rule if rule.type == "pull_request"]) == 1 &&
      alltrue([
        for rule in ruleset.rules : rule.type != "pull_request" || try(rule.parameters.require_extra_approval_for_unattributed_changes, null) == false
      ])
    ])
    error_message = "Every REST-managed ruleset must set the extra approval parameter to false on its pull_request rule."
  }
}

run "derives_ci_gate_property_from_default_branch_workflow_call" {
  command = plan

  variables {
    github_owner              = "example-org"
    dryvist_org_extras        = false
    automation_bypass_app_ids = [1]
    private_repo_overrides = {
      without-gate = {
        description         = ""
        topics              = []
        visibility          = "private"
        archived            = false
        allow_update_branch = false
      }
    }
  }

  override_data {
    target = data.github_repositories.org
    values = {
      names = ["with-gate"]
    }
  }

  override_data {
    target = data.github_repositories.existing
    values = {
      names = []
    }
  }

  override_data {
    target = data.github_tree.ci_gate
    values = {
      entries = [{
        mode = "100644"
        path = ".github/workflows/ci.yml"
        sha  = "with-gate-workflow"
        size = 1
        type = "blob"
      }]
    }
  }

  override_data {
    target = data.github_repository_file.ci_gate
    values = {
      content = "name: CI\non: pull_request\njobs:\n  gate:\n    uses: JacobPEvans/.github/.github/workflows/_ci-gate.yml@v1\n"
    }
  }

  assert {
    condition = (
      github_repository_custom_property.ci_gate["with-gate"].property_value == toset(["true"]) &&
      github_repository_custom_property.ci_gate["without-gate"].property_value == toset(["false"])
    )
    error_message = "The shared gate caller must set ci_gate=true on its repo, false without a caller, and no org schema."
  }
}

run "private_merge_gate_repos_share_one_gate" {
  command = plan

  variables {
    github_owner              = "JacobPEvans"
    automation_bypass_app_ids = [1]
    private_repo_overrides = {
      example-a = {
        description         = ""
        topics              = []
        visibility          = "private"
        archived            = false
        allow_update_branch = false
        merge_gate          = { gate = { context = "gate / Merge Gate" } }
      }
      example-b = {
        description         = ""
        topics              = []
        visibility          = "private"
        archived            = false
        allow_update_branch = false
        merge_gate          = { gate = { context = "gate / Merge Gate" } }
      }
    }
  }

  override_data {
    target = data.github_repositories.existing
    values = {
      names = []
    }
  }

  assert {
    condition     = jsonencode(local.merge_gate_contexts["gate"].repos) == jsonencode(["example-a", "example-b"]) && local.merge_gate_contexts["gate"].context == "gate / Merge Gate"
    error_message = "Private repos on the same gate must all be listed in that gate's ruleset."
  }
}

run "placeholder_org_disables_org_specific_extras" {
  command = plan

  variables {
    github_owner              = "example-org"
    dryvist_org_extras        = false
    automation_bypass_app_ids = [1]
    hermes_webhook_url        = "https://example.invalid/hook"
    hermes_webhook_secret     = "test-secret"
  }

  override_data {
    target = data.github_repositories.existing
    values = {
      names = []
    }
  }

  assert {
    condition     = local.org == "example-org"
    error_message = "The selected org must come from the workspace owner."
  }

  assert {
    condition     = local.managed_repos[".github"].visibility == "public" && !contains(keys(local.adopted_repos), ".github")
    error_message = "A missing defaults repository must be planned for creation as public."
  }

  assert {
    condition = alltrue([
      length(restapi_object.docs_publisher) == 0,
      length(github_organization_custom_properties.docs) == 0,
      length(github_organization_webhook.hermes_pr_review) == 0,
      length(github_actions_variable.iac_drift_enabled) == 0,
      length(github_organization_ruleset.org_copilot_review) == 0,
      length(github_organization_ruleset.org_release_freeze) == 0,
      length(github_organization_ruleset.org_merge_gate) == 0,
      length(github_repository_custom_property.upstream_fork) == 0,
      length(restapi_object.org_upstream_fork_protection) == 0,
      length(github_actions_runner_group.homelab) == 0,
    ])
    error_message = "Organization-specific resources must have no instances when the opt-in is false."
  }

  assert {
    condition     = length(module.repo_settings) == 2
    error_message = "Shared repository settings must remain enabled."
  }
}
