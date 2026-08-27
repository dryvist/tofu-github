# Git-flow pilot wiring.
#
# A repo opts into the git-flow model with `gitflow: true` in config/repos.yml.
# local.gitflow_repos derives that opted-in set once, and everything git-flow
# reads from it: the develop branch + default-branch switch below, and the
# git-flow rulesets in rulesets.tf. Adding or removing a repo from the pilot is
# a one-line edit to config/repos.yml — never a second list to keep in sync.
locals {
  gitflow_repos = [for name, cfg in local.repos : name if try(cfg.gitflow, false)]
}

# Define the custom property at the org level to tag git-flow enabled repositories
resource "github_organization_custom_properties" "gitflow" {
  property_name = "gitflow"
  value_type    = "true_false"
}

# Attach the custom property to all gitflow repos
resource "github_repository_custom_property" "gitflow" {
  for_each = toset(local.gitflow_repos)

  repository     = each.value
  property_name  = github_organization_custom_properties.gitflow.property_name
  property_type  = "true_false"
  property_value = ["true"]
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
# Any repo added to the git-flow set AFTER it has already been running git-flow
# out of band arrives with develop present. github_branch only CREATES, and a
# create against an existing ref 422s (the same failure migrations.tf documents
# for the renamed repo), so each such repo needs a one-shot import. Expect to
# add a block here whenever `gitflow: true` is set on a repo that is not brand
# new; drop it again once the apply has landed.
#
# The sibling github_repository_custom_property.gitflow needs NO import: its
# create calls the GitHub CreateOrUpdateCustomProperties endpoint, so it adopts
# an already-set property value instead of failing.
import {
  to = github_branch.develop["llm-prompt-evals"]
  id = "llm-prompt-evals:develop"
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
