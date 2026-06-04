# Org-level GitHub Actions variables.
#
# Canonical home for AI model selection consumed by the reusable workflows in
# the org's ai-workflows repo. An org variable is inherited by every repo
# (public + private), so callers need neither a repo-level copy nor a
# per-workflow literal model fallback. Values live in
# config/actions-variables.yml so this resource carries no inline config.
#
# Cost impact: free. Org-level Actions variables incur no per-seat or metered
# cost on any plan or repo visibility.
resource "github_actions_organization_variable" "ai_models" {
  for_each = local.ai_model_variables

  variable_name = each.key
  value         = each.value
  visibility    = "all"
}
