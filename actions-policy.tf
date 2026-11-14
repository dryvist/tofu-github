# Organization Actions settings the GitHub provider has no resource for.
#
# Fork pull-request workflows from contributors always require approval, the
# strictest policy, before any job can run on an org runner.
resource "restapi_object" "fork_pr_contributor_approval" {
  provider = restapi.no_body

  # The setting is a singleton: every verb targets the same path, PUT replaces
  # the object, and the API offers no POST and no DELETE.
  path           = "/orgs/${var.github_owner}/actions/permissions/fork-pr-contributor-approval"
  create_path    = "/orgs/${var.github_owner}/actions/permissions/fork-pr-contributor-approval"
  read_path      = "/orgs/${var.github_owner}/actions/permissions/fork-pr-contributor-approval"
  update_path    = "/orgs/${var.github_owner}/actions/permissions/fork-pr-contributor-approval"
  destroy_path   = "/orgs/${var.github_owner}/actions/permissions/fork-pr-contributor-approval"
  object_id      = "fork-pr-contributor-approval"
  create_method  = "PUT"
  update_method  = "PUT"
  destroy_method = "PUT"

  data = jsonencode({
    approval_policy = var.fork_pr_contributor_approval
  })

  # Destroying the resource PUTs the strict policy back instead of a DELETE.
  destroy_data = jsonencode({
    approval_policy = var.fork_pr_contributor_approval
  })
}

# The built-in Default runner group reaches every repository, public ones
# included, but only once fork workflows always face the approval above.
resource "github_actions_runner_group" "default" {
  name                       = "Default"
  visibility                 = "all"
  allows_public_repositories = var.default_runner_group_allows_public_repositories

  depends_on = [restapi_object.fork_pr_contributor_approval]

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = github_actions_runner_group.default
  id = "1"
}
