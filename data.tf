# Resolve the numeric repository ID of the org's `.github` repo at apply
# time, so org rulesets that reference workflows living in it never carry
# a literal ID. The provider's `owner` setting determines the org; this
# data source just names the repo.
data "github_repository" "dot_github" {
  name = ".github"
}
