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
    approval_policy = "all_external_contributors"
  })

  # Destroying the resource PUTs the strict policy back instead of a DELETE.
  destroy_data = jsonencode({
    approval_policy = "all_external_contributors"
  })
}

# The built-in Default runner group reaches every repository, public ones
# included, but only once fork workflows always face the approval above.
resource "github_actions_runner_group" "default" {
  name                       = "Default"
  visibility                 = "all"
  allows_public_repositories = true

  depends_on = [restapi_object.fork_pr_contributor_approval]

  lifecycle {
    prevent_destroy = true
  }
}

# The group exists in every organisation with id 1; tests switch the adoption off.
import {
  for_each = var.codeql_import_enabled ? toset(["1"]) : toset([])
  to       = github_actions_runner_group.default
  id       = each.value
}
