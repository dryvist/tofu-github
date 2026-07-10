# Per-repo AI caller parameters (AI_REPO_CONTEXT / AI_CI_STRUCTURE /
# AI_CI_WORKFLOW_NAME / AI_EXTRA_TOOLS) used to be fanned out here as
# `github_actions_variable.ai` across every repo. They were removed: the values
# duplicated data the workflow already has at runtime — repo_context is just the
# repo's own `github.event.repository.description`, and workflow_name is
# `github.event.workflow_run.name` — so the ai-workflows reusables now derive
# them from the `github.*` context instead of reading `${{ vars.AI_* }}`. This
# also retired the drift between the hand-maintained copies and the real repo
# descriptions, and removed the only reason the Terrakube workspace token needed
# Actions `Variables: write` (tofu-github#37).

# Org-wide repo list consumed by ai-workflows' hourly review-thread-resolver
# sweep (dogfood-review-thread-sweep.yml). Derived from the same
# config/ai-callers.yml inventory as everything else in this file, plus the
# hub repo itself, so opting a repo in or out of the sweep is one YAML line.
resource "github_actions_organization_variable" "ai_sweep_repos" {
  variable_name = "AI_SWEEP_REPOS"
  value         = join(",", sort(concat(keys(local.ai.repos), ["ai-workflows"])))
  visibility    = "all"
}
