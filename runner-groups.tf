# Self-hosted runner group that only private repositories can use. Runners
# that register into it never pick up a public repository's jobs.
# `visibility = "private"` is not supported by the API; `all` together with
# `allows_public_repositories = false` gives the same reach.
resource "github_actions_runner_group" "homelab" {
  name                       = "homelab"
  visibility                 = "all"
  allows_public_repositories = false
}

locals {
  # ai-workflows reusables whose jobs run on self-hosted runners by default.
  homelab_ai_workflows = [
    "cc-release-notes",
    "docs-drift",
    "docs-publisher",
    "docs-sync",
    "policy-gate",
    "pr-agent",
    "pricing-discovery",
    "repo-hygiene-digest",
    "thread-triage",
  ]
  homelab_ai_refs = ["refs/heads/main", "refs/tags/v1"]
}

# Self-hosted runner group that public repositories can use, limited to the
# ai-workflows reusables above at the release refs. Only jobs defined in a
# listed workflow, at a listed ref, are dispatched to these runners.
resource "github_actions_runner_group" "homelab_ai" {
  name                       = "homelab-ai"
  visibility                 = "all"
  allows_public_repositories = true
  restricted_to_workflows    = true
  selected_workflows = [
    for pair in setproduct(local.homelab_ai_workflows, local.homelab_ai_refs) :
    "dryvist/ai-workflows/.github/workflows/${pair[0]}.yml@${pair[1]}"
  ]
}

# GitHub's built-in Default group (id 1). Kept private-only so a runner that
# registers without a group can never pick up a public repository's jobs.
import {
  to = github_actions_runner_group.default
  id = "1"
}

resource "github_actions_runner_group" "default" {
  name                       = "Default"
  visibility                 = "all"
  allows_public_repositories = false
}
