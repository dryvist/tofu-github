# The org-wide label set, applied to every unarchived repo.
#
# The single definition is `.github/labels.yml` in the org's `.github` repo
# (data.github_repository_file.labels). Repos are enumerated at plan time
# (data.github_repositories.org), so no repo name is written here and a
# new repo is covered on the next apply.
#
# github_issue_label (not the authoritative github_issue_labels) so labels a
# repo carries beyond the canonical set are left alone. An existing label with
# the same name is updated in place.
locals {
  labels = yamldecode(data.github_repository_file.labels.content)

  repo_labels = {
    for pair in setproduct(data.github_repositories.org.names, local.labels) :
    "${pair[0]}/${pair[1].name}" => {
      repository  = pair[0]
      name        = pair[1].name
      color       = pair[1].color
      description = pair[1].description
    }
  }
}

resource "github_issue_label" "org" {
  for_each = local.repo_labels

  repository  = each.value.repository
  name        = each.value.name
  color       = each.value.color
  description = each.value.description
}

# Carries the state of the earlier per-repo label resource (same
# "<repo>/<label>" keys) over to the org resource.
moved {
  from = github_issue_label.ai
  to   = github_issue_label.org
}

# The labels each repo already carries, read at plan time.
data "github_issue_labels" "existing" {
  for_each = toset(data.github_repositories.org.names)

  repository = each.key
}

locals {
  # Lower-cased: GitHub treats label names case-insensitively.
  existing_label_names = {
    for repo, d in data.github_issue_labels.existing :
    repo => [for l in d.labels : lower(l.name)]
  }
}

# github_issue_label create does not adopt an existing label (GitHub answers
# 422 already_exists), so every desired label that already exists is imported
# instead. Import id format: "<repository>:<name>". An import whose target is
# already in state is a no-op; missing labels fall through to create.
import {
  for_each = {
    for k, v in local.repo_labels : k => v
    if contains(local.existing_label_names[v.repository], lower(v.name))
  }

  to = github_issue_label.org[each.key]
  id = "${each.value.repository}:${each.value.name}"
}
