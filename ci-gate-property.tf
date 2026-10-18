# Mark repositories whose default branch calls the shared CI merge gate.
data "github_repository_branches" "ci_gate" {
  for_each = {
    for name, repo in data.github_repository.enumerated : name => repo.default_branch
    if try(trimspace(repo.default_branch), "") != ""
  }

  repository = each.key
}

# An empty repo lists no branches; reading its default branch fails with 409.
data "github_branch" "ci_gate" {
  for_each = {
    for name, listed in data.github_repository_branches.ci_gate : name => data.github_repository.enumerated[name].default_branch
    if contains(listed.branches[*].name, data.github_repository.enumerated[name].default_branch)
  }

  repository = each.key
  branch     = each.value
}

data "github_tree" "ci_gate" {
  # An empty repo has no branch to read, so it has no tree.
  for_each = { for name, branch in data.github_branch.ci_gate : name => branch if try(branch.sha, "") != "" }

  repository = each.key
  tree_sha   = each.value.sha
  recursive  = true
}

locals {
  # Any org's `.github` home at any ref; the job id fixes the required context to "gate / Merge Gate".
  ci_gate_reusable_workflow = "^[^/]+/\\.github/\\.github/workflows/_ci-gate\\.yml@"

  ci_gate_workflow_files = {
    for workflow in flatten([
      for repo, tree in data.github_tree.ci_gate : [
        for entry in tree.entries : {
          key        = "${repo}|${entry.path}"
          repository = repo
          path       = entry.path
        } if entry.type == "blob" && startswith(entry.path, ".github/workflows/") &&
        (endswith(entry.path, ".yml") || endswith(entry.path, ".yaml"))
      ]
    ]) : workflow.key => workflow
  }

  ci_gate_repos = toset(distinct([
    for key, workflow in local.ci_gate_workflow_files : workflow.repository
    if try(anytrue([
      for id, job in yamldecode(data.github_repository_file.ci_gate[key].content).jobs :
      id == "gate" && can(regex(local.ci_gate_reusable_workflow, try(job.uses, "")))
    ]), false)
  ]))
}

# Tree entries prove the selected paths exist at this default-branch commit.
data "github_repository_file" "ci_gate" {
  for_each = local.ci_gate_workflow_files

  repository = each.value.repository
  branch     = data.github_branch.ci_gate[each.value.repository].sha
  file       = each.value.path
}

# Set the enterprise-owned property on every unarchived managed repository.
resource "github_repository_custom_property" "ci_gate" {
  for_each = toset([
    for name, cfg in local.managed_repos : name if !try(cfg.archived, false)
  ])

  repository     = each.value
  property_name  = "ci_gate"
  property_type  = "true_false"
  property_value = [tostring(contains(local.ci_gate_repos, each.value))]

  depends_on = [module.repo_settings]
}
