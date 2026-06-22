# Per-repo Actions variables that parameterize the AI caller workflows. Keeping
# these in repo variables (read as ${{ vars.AI_* }} at runtime) is what lets the
# caller .yml files stay (near-)identical across repos instead of being rendered
# per repo. Sourced from config/ai-callers.yml — the same single source of truth
# as labels.tf. (ci_workflow_name is also baked into ai-ci.yml's workflow_run
# trigger by sync-ai-callers.yml, since ${{ }} is not evaluated in `on:`.)
locals {
  # Actions variable name -> key in each repo's ai-callers.yml block.
  ai_variable_keys = {
    AI_REPO_CONTEXT     = "repo_context"
    AI_CI_STRUCTURE     = "ci_structure"
    AI_EXTRA_TOOLS      = "extra_tools"
    AI_CI_WORKFLOW_NAME = "ci_workflow_name"
  }

  ai_repo_variables = {
    for key, v in merge([
      for repo, cfg in local.ai.repos : {
        for var_name, src_key in local.ai_variable_keys : "${repo}/${var_name}" => {
          repo  = repo
          name  = var_name
          value = cfg[src_key]
        }
      }
    ]...) : key => v if v.value != ""
    # GitHub rejects empty Actions variable values; an unset var already reads as
    # "" in ${{ vars.* }}, so skipping empties (e.g. extra_tools) is equivalent.
  }
}

resource "github_actions_variable" "ai" {
  for_each = local.ai_repo_variables

  repository    = each.value.repo
  variable_name = each.value.name
  value         = each.value.value
}
