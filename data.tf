# Resolve the numeric repository ID of the org's `.github` repo at apply
# time, so org rulesets that reference workflows living in it never carry
# a literal ID. The provider's `owner` setting determines the org; this
# data source just names the repo.
data "github_repository" "dot_github" {
  name = ".github"
}

# Every unarchived repo in the org, resolved at plan time.
#
# STAGED AND INERT: count is 0 unless var.manage_all_repos is set, so a normal
# plan never issues this search. It exists so the opt-in inventory in
# config/repos.yml can be flipped to an opt-OUT model — the reason repos in
# this org are born ungoverned is that nothing enrolls them, and enumerating
# the org is the only way to invert that default. See the variable's docstring
# for the blast radius.
#
# The org login is not written here: it is split back out of the `.github`
# repo's full_name, which the provider's own `owner` setting determines. Same
# reasoning as the data source above — reference the live value, never a
# literal identity.
data "github_repositories" "org" {
  count = var.manage_all_repos ? 1 : 0
  query = "org:${local.org} archived:false"
}

# Live metadata per enumerated repo, so enrolling a repo INHERITS its current
# description, topics and visibility instead of blanking them on first apply.
data "github_repository" "enumerated" {
  for_each = var.manage_all_repos ? toset(data.github_repositories.org[0].names) : toset([])
  name     = each.value
}
