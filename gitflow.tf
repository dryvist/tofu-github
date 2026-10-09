# Git-flow pilot wiring.
#
# A repo is git-flow when its live default branch is develop, or when its
# config/repos.yml entry sets `gitflow: true` (which wins wholesale; see
# repos.tf). local.gitflow_repos derives that set once, and everything git-flow
# reads from it: the develop branch + default-branch switch below, and the
# git-flow rulesets. Never a second list to keep in sync.
locals {
  gitflow_repos = [for name, cfg in local.managed_repos : name if try(cfg.gitflow, false)]
}

# Define the custom property at the org level to tag git-flow enabled repositories
resource "github_organization_custom_properties" "gitflow" {
  property_name = "gitflow"
  value_type    = "true_false"
}

# Set the custom property on every unarchived managed repo: "true" on git-flow
# repos, "false" on the rest. Setting "false" explicitly clears a value left
# over from repo creation, which would otherwise keep a trunk repo under the
# property-targeted git-flow rulesets. Archived repos are read-only and skipped.
resource "github_repository_custom_property" "gitflow" {
  for_each = toset([
    for name, cfg in local.managed_repos : name if !try(cfg.archived, false)
  ])

  repository     = each.value
  property_name  = github_organization_custom_properties.gitflow.property_name
  property_type  = "true_false"
  property_value = [tostring(contains(local.gitflow_repos, each.value))]
}

# develop branch, cut from main for each git-flow repo. github_branch only
# CREATES the branch — it does not reconcile later divergence — so once develop
# exists and moves ahead of main through normal git-flow work, Terraform leaves
# its ref alone. source_branch = main requires main to already exist (it does on
# every pilot repo).
resource "github_branch" "develop" {
  for_each = toset(local.gitflow_repos)

  repository    = each.value
  branch        = "develop"
  source_branch = "main"
}

# Adopt a develop branch that already exists.
#
# github_branch only CREATES, and a create against an existing ref 422s, so a
# git-flow repo whose live default branch is already develop is imported
# instead. Derived from the live org, never a per-repo block: an import whose
# target is already in state is a no-op, so the set can stay as wide as this.
#
# The sibling github_repository_custom_property.gitflow needs NO import: its
# create calls the GitHub CreateOrUpdateCustomProperties endpoint, so it adopts
# an already-set property value instead of failing.
import {
  for_each = toset([
    for name in local.gitflow_repos : name
    if try(data.github_repository.enumerated[name].default_branch, "") == "develop"
  ])
  to = github_branch.develop[each.key]
  id = "${each.key}:develop"
}

# Make develop the default branch on git-flow repos: new clones and new PRs
# target the integration branch, while main is reserved for releases. The
# reference to github_branch.develop makes this depend on the branch existing
# first. Switching the default is what makes the org ~DEFAULT_BRANCH rulesets
# follow develop — which is exactly why rulesets.tf excludes git-flow repos from
# the standard default-branch rulesets and binds develop-specific rules by
# literal ref instead.
resource "github_branch_default" "develop" {
  for_each = toset(local.gitflow_repos)

  repository = each.value
  branch     = github_branch.develop[each.key].branch
}
