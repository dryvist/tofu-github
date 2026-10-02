# Resolve the numeric repository ID of the org's `.github` repo at apply
# time, so org rulesets that reference workflows living in it never carry
# a literal ID. The provider's `owner` setting determines the org; this
# data source just names the repo.
data "github_repository" "dot_github" {
  name = ".github"
}

# Every unarchived repo in the org, public and private, forks included,
# resolved at plan time. The single org enumeration: repos.tf brings each one
# under module.repo_settings and labels.tf applies the org label set to each.
#
# The org login is not written here: it is split back out of the `.github`
# repo's full_name, which the provider's own `owner` setting determines. Same
# reasoning as the data source above — reference the live value, never a
# literal identity.
data "github_repositories" "org" {
  query = "org:${local.org} fork:true archived:false"
}

# Every repo that ALREADY EXISTS in the org, archived included, resolved at
# plan time. Kept separate from the enumeration above because its filter
# differs: archived repos must be included here (see below).
#
# This exists to answer one question the config cannot answer from its own
# text: for each entry in config/repos.yml, does the repo exist yet? An
# import block aimed at a repo that does not exist fails the plan, so
# repos.tf intersects this list with the managed inventory to decide which
# entries are ADOPTED (import) and which are CREATED.
#
# Deriving it beats a per-repo flag. A flag would record how a repo came to
# be — history, true exactly once — and every future entry would need a
# human to know whether the repo pre-exists. This asks GitHub instead, so
# the same repos.yml entry is correct before creation and forever after.
#
# `archived:false` is deliberately ABSENT: archived repos are still managed
# (nix-ai-server), and omitting them here would classify them as
# non-existent and make Terraform try to recreate them. `fork:true` is
# deliberately PRESENT for the same reason: repository search leaves forks
# out unless asked, so a managed fork would otherwise be planned as a create.
#
# Cost: one search-API call per plan. If the search is stale or unavailable
# the failure is safe and loud — a genuinely existing repo drops out of the
# adopted set, Terraform attempts a create, and GitHub rejects the duplicate
# name. It cannot silently destroy or blank a repo.
data "github_repositories" "existing" {
  query = "org:${local.org} fork:true"
}

# Live metadata per enumerated repo, so enrolling a repo INHERITS its current
# description, topics and visibility instead of blanking them on first apply.
data "github_repository" "enumerated" {
  for_each = toset(data.github_repositories.org.names)
  name     = each.value
}

# The canonical label set, read at plan time from the `.github` repo so this
# config carries no copy of it. labels.tf applies it to every
# enumerated repo.
data "github_repository_file" "labels" {
  repository = data.github_repository.dot_github.name
  branch     = data.github_repository.dot_github.default_branch
  file       = ".github/labels.yml"
}
