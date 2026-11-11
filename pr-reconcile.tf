# Owners the PR Reconcile sweep covers, set as the PR_RECONCILE_OWNERS variable
# on the repository that runs the sweep. Only an owner with
# config/orgs/<owner>/pr-reconcile.yml manages it.
resource "github_actions_variable" "pr_reconcile_owners" {
  count = local.pr_reconcile_config == null ? 0 : 1

  repository    = local.pr_reconcile_config.sweep_repository
  variable_name = "PR_RECONCILE_OWNERS"
  value         = join(",", local.pr_reconcile_config.owners)
}
