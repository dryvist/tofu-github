# Authentication: the provider reads the GITHUB_TOKEN environment variable.
# Managing org-level rulesets requires a token with `admin:org`. Apply with the
# ORG_ADMIN token tier (gh-claude-org-admin); the default DRYVIST tier is
# read-only on org rulesets and will 403 on apply.
provider "github" {
  owner = "dryvist"
}
