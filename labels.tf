# Issue-label taxonomy the AI chain depends on (ai:ready trigger, type:*, size:*,
# priority:*, ai:created), applied to every repo opted in via config/ai-callers.yml.
#
# github_issue_label checks for an existing label and updates it, otherwise
# creates — so it ADOPTS pre-existing labels (default repo labels, or an ai:ready
# created during earlier manual runs) instead of 422-ing. No import blocks needed.
locals {
  # Flatten (repo × label) into a single keyed map for one for_each.
  ai_repo_labels = merge([
    for repo in keys(local.ai.repos) : {
      for name, label in local.ai.labels : "${repo}/${name}" => {
        repo        = repo
        name        = name
        color       = label.color
        description = try(label.description, "")
      }
    }
  ]...)
}

resource "github_issue_label" "ai" {
  for_each = local.ai_repo_labels

  repository  = each.value.repo
  name        = each.value.name
  color       = each.value.color
  description = each.value.description
}
