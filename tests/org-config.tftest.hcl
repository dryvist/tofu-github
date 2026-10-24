mock_provider "github" {
  mock_resource "github_repository" {
    defaults = {
      repo_id = 1
    }
  }

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

  mock_data "github_repository_branches" {
    defaults = {
      branches = [{ name = "main", protected = false }]
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

mock_provider "vault" {
  mock_data "vault_kv_secret_v2" {
    defaults = {
      data_json = <<-JSON
        {
          "private_repo_overrides": {
            "example-a": {
              "description": "",
              "topics": [],
              "visibility": "private",
              "merge_gate": { "gate": { "context": "gate / Merge Gate" } }
            },
            "example-b": {
              "description": "",
              "topics": [],
              "visibility": "private",
              "merge_gate": { "gate": { "context": "gate / Merge Gate" } }
            }
          }
        }
        JSON
    }
  }
}

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
    condition     = local.private_repo_overrides == {}
    error_message = "An org without private merge-gate config must not read private repo overrides."
  }

  assert {
    condition     = length(local.merge_gate_contexts) == 0 && length(local.copilot_review_targets) == 0 && length(local.iac_drift.repos) == 0 && length(local.docs_publisher) == 0
    error_message = "Absent optional org files must disable their opt-in policies."
  }

  assert {
    condition = (
      length(local.managed_repos) == 3 &&
      local.managed_repos[".github"].visibility == "public" &&
      local.managed_repos[".github-private"].visibility == "private" &&
      local.managed_repos[".github-private"].description == "Members-only org profile and index" &&
      !try(local.managed_repos[".github-private"].archived, false) &&
      local.managed_repos["sample"].visibility == "public"
    )
    error_message = "Both org profile repos must always be managed alongside repos enumerated from GitHub."
  }

  assert {
    condition     = length(module.repo_settings) == 3
    error_message = "Every managed repository must receive the shared repository settings module."
  }

  assert {
    condition = (
      github_organization_custom_properties.family.required == false &&
      github_organization_custom_properties.family.default_value == null &&
      toset(github_organization_custom_properties.family.allowed_values) == toset(local.family_values) &&
      length(github_repository_custom_property.family) == 0 &&
      github_repository_custom_property.gitflow[".github-private"].property_value == toset(["false"]) &&
      github_repository_custom_property.ci_gate[".github-private"].property_value == toset(["false"])
    )
    error_message = "Family must remain optional and unset until configured, while existing repo properties cover the private profile repo."
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
    condition     = github_repository_custom_property.ci_gate["with-gate"].property_value == toset(["true"])
    error_message = "The shared gate caller must set ci_gate=true on its repo."
  }
}

run "skips_ci_gate_branch_read_on_empty_repo" {
  command = plan

  variables {
    github_owner              = "example-org"
    dryvist_org_extras        = false
    automation_bypass_app_ids = [1]
  }

  override_data {
    target = data.github_repositories.org
    values = {
      names = ["empty"]
    }
  }

  override_data {
    target = data.github_repositories.existing
    values = {
      names = []
    }
  }

  override_data {
    target = data.github_repository_branches.ci_gate
    values = {
      branches = []
    }
  }

  assert {
    condition     = length(data.github_branch.ci_gate) == 0
    error_message = "An empty repo must not have its default branch read."
  }

  assert {
    condition     = github_repository_custom_property.ci_gate["empty"].property_value == toset(["false"])
    error_message = "An empty repo must get ci_gate=false."
  }
}

run "derives_ci_gate_from_sha_pinned_org_home_caller" {
  command = plan

  variables {
    github_owner              = "example-org"
    dryvist_org_extras        = false
    automation_bypass_app_ids = [1]
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
      content = "name: CI\non: pull_request\njobs:\n  gate:\n    uses: dryvist/.github/.github/workflows/_ci-gate.yml@1f09b25303a04bf276087348059671728ffea50a # v1.13.2\n"
    }
  }

  assert {
    condition     = github_repository_custom_property.ci_gate["with-gate"].property_value == toset(["true"])
    error_message = "The shared gate caller must set ci_gate=true on its repo."
  }
}

run "ignores_ci_gate_caller_under_other_job_id" {
  command = plan

  variables {
    github_owner              = "example-org"
    dryvist_org_extras        = false
    automation_bypass_app_ids = [1]
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
      content = "name: CI\non: pull_request\njobs:\n  ci:\n    uses: JacobPEvans/.github/.github/workflows/_ci-gate.yml@v1\n"
    }
  }

  assert {
    condition     = github_repository_custom_property.ci_gate["with-gate"].property_value == toset(["false"])
    error_message = "Only a `gate` job yields the required \"gate / Merge Gate\" context."
  }
}

run "private_merge_gate_repos_share_one_gate" {
  command = plan

  variables {
    github_owner              = "tofu-test-fixture"
    dryvist_org_extras        = false
    automation_bypass_app_ids = [1]
  }

  override_data {
    target = data.github_repositories.existing
    values = {
      names = []
    }
  }

  assert {
    condition = (
      length(setintersection(toset(keys(local.repos)), toset(["example-a", "example-b"]))) == 2 &&
      length(setintersection(toset(local.merge_gate_contexts["gate"].repos), toset(["example-a", "example-b"]))) == 2 &&
      local.merge_gate_contexts["gate"].context == "gate / Merge Gate"
    )
    error_message = "OpenBao repo metadata and merge-gate contexts must be merged into org config."
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
    condition = (
      local.managed_repos[".github"].visibility == "public" &&
      !contains(keys(local.adopted_repos), ".github") &&
      local.managed_repos[".github-private"].visibility == "private" &&
      !contains(keys(local.adopted_repos), ".github-private")
    )
    error_message = "Missing profile repositories must be planned for creation with their declared visibility."
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
      length(github_organization_ruleset.markdown_lint) == 0,
      length(github_organization_ruleset.conventions) == 0,
      length(github_organization_ruleset.ai_review) == 0,
    ])
    error_message = "Organization-specific resources must have no instances when the opt-in is false."
  }

  assert {
    condition     = length(module.repo_settings) == 3
    error_message = "Shared repository settings must remain enabled."
  }
}

run "required_workflow_rulesets_use_default_enforcement" {
  command = plan

  variables {
    github_owner              = "example-org"
    dryvist_org_extras        = true
    automation_bypass_app_ids = [1]
  }

  override_data {
    target = data.github_repositories.org
    values = {
      names = []
    }
  }

  override_data {
    target = data.github_repositories.existing
    values = {
      names = []
    }
  }

  assert {
    condition = (
      length(github_organization_ruleset.markdown_lint) == 1 &&
      github_organization_ruleset.markdown_lint[0].enforcement == "evaluate" &&
      length(github_organization_ruleset.conventions) == 1 &&
      github_organization_ruleset.conventions[0].enforcement == "evaluate" &&
      length(github_organization_ruleset.ai_review) == 1 &&
      github_organization_ruleset.ai_review[0].enforcement == "evaluate"
    )
    error_message = "Required-workflow rulesets must use their default enforcement and have one instance when enabled."
  }

  assert {
    condition = (
      length(github_organization_ruleset.code_scanning) == 1 &&
      github_organization_ruleset.code_scanning[0].enforcement == "active" &&
      github_organization_ruleset.code_scanning[0].conditions[0].ref_name[0].include == ["~DEFAULT_BRANCH", "refs/heads/main"] &&
      github_organization_ruleset.code_scanning[0].conditions[0].repository_name[0].include == sort(data.github_repositories.public_for_codeql.names) &&
      one(github_organization_ruleset.code_scanning[0].rules[0].required_code_scanning[0].required_code_scanning_tool).tool == "CodeQL" &&
      one(github_organization_ruleset.code_scanning[0].rules[0].required_code_scanning[0].required_code_scanning_tool).alerts_threshold == "errors" &&
      one(github_organization_ruleset.code_scanning[0].rules[0].required_code_scanning[0].required_code_scanning_tool).security_alerts_threshold == "high_or_higher"
    )
    error_message = "CodeQL merge protection must use the live default-setup repo set and the configured thresholds."
  }
}
