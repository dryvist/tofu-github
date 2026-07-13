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
