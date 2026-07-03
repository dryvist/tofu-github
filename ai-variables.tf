# Per-repo Actions variables that parameterize the AI caller workflows. Keeping
# these in repo variables (read as ${{ vars.AI_* }} at runtime) is what lets the
# caller .yml files stay (near-)identical across repos instead of being rendered
# per repo. Sourced from config/ai-callers.yml — the same single source of truth
# as labels.tf.
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

# Org-wide repo list consumed by ai-workflows' hourly review-thread-resolver
# sweep (dogfood-review-thread-sweep.yml). Derived from the same
# config/ai-callers.yml inventory as everything else in this file, plus the
# hub repo itself, so opting a repo in or out of the sweep is one YAML line.
resource "github_actions_organization_variable" "ai_sweep_repos" {
  variable_name = "AI_SWEEP_REPOS"
  value         = join(",", sort(concat(keys(local.ai.repos), ["ai-workflows"])))
  visibility    = "all"
}
