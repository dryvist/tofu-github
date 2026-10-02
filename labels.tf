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
