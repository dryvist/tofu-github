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
