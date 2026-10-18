# Self-hosted runner group that only private repositories can use. Runners
# that register into it never pick up a public repository's jobs.
# `visibility = "private"` is not supported by the API; `all` together with
# `allows_public_repositories = false` gives the same reach.
resource "github_actions_runner_group" "homelab" {
  count                      = var.dryvist_org_extras ? 1 : 0
  name                       = "homelab"
  visibility                 = "all"
  allows_public_repositories = false
}

moved {
  from = github_actions_runner_group.homelab
  to   = github_actions_runner_group.homelab[0]
}

resource "github_actions_runner_group" "pr_agent" {
  count = local.self_hosted_runners ? 1 : 0

  name                       = "pr-agent"
  visibility                 = "all"
  allows_public_repositories = true
  restricted_to_workflows    = true
  selected_workflows         = local.runner_group_selected_workflows
}
