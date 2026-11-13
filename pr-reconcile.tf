# Owners the PR Reconcile sweep covers, set as the PR_RECONCILE_OWNERS variable
# on the repository that runs the sweep. Only an owner with
# config/orgs/<owner>/pr-reconcile.yml manages it; like ai-untrusted.yml, the
# file is the opt-in, so dryvist_org_extras does not gate it.
resource "github_actions_variable" "pr_reconcile_owners" {
  count = local.pr_reconcile_config == null ? 0 : 1

  repository    = try(local.pr_reconcile_config.sweep_repository, "")
  variable_name = "PR_RECONCILE_OWNERS"
  value         = join(",", try(local.pr_reconcile_config.owners, []))

  lifecycle {
    precondition {
      condition     = try(local.pr_reconcile_config.sweep_repository, "") != "" && length(try(local.pr_reconcile_config.owners, [])) > 0
      error_message = "config/orgs/<owner>/pr-reconcile.yml needs sweep_repository and a non-empty owners list."
    }
  }
}

resource "github_actions_variable" "pr_reconcile_claude_bot_id" {
  count = local.pr_reconcile_config == null ? 0 : 1

  repository    = try(local.pr_reconcile_config.sweep_repository, "")
  variable_name = "GH_APP_CLAUDE_BOT_ID"
  value         = try(local.pr_reconcile_config.claude_bot_app_id, "")

  lifecycle {
    precondition {
      condition     = try(local.pr_reconcile_config.sweep_repository, "") != "" && try(local.pr_reconcile_config.claude_bot_app_id, "") != ""
      error_message = "config/orgs/<owner>/pr-reconcile.yml needs sweep_repository and claude_bot_app_id."
    }
  }
}

data "github_repository" "pr_reconcile" {
  count = try(local.pr_reconcile_config.runner_group, null) == null ? 0 : 1

  name = try(local.pr_reconcile_config.sweep_repository, "")
}

resource "github_actions_runner_group" "pr_reconcile" {
  count = try(local.pr_reconcile_config.runner_group, null) == null ? 0 : 1

  name                    = try(local.pr_reconcile_config.runner_group, "")
  visibility              = "selected"
  selected_repository_ids = [data.github_repository.pr_reconcile[0].repo_id]
  restricted_to_workflows = true
  selected_workflows = [
    "${local.org}/${try(local.pr_reconcile_config.sweep_repository, "")}/.github/workflows/pr-reconcile-sweep.yml@refs/heads/main",
    "${local.org}/${try(local.pr_reconcile_config.sweep_repository, "")}/.github/workflows/pr-reconcile.yml@refs/heads/main",
  ]
  # The public sweep repository needs public-repository access. Selection of
  # that repository and these workflow refs limits which jobs can use the group.
  allows_public_repositories = true

  lifecycle {
    precondition {
      condition     = try(local.pr_reconcile_config.runner_group, "") != "" && try(local.pr_reconcile_config.sweep_repository, "") != ""
      error_message = "config/orgs/<owner>/pr-reconcile.yml runner_group requires a non-empty runner_group and sweep_repository."
    }
  }
}
