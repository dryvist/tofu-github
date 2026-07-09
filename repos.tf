# Per-repo settings for the repos this config governs. The repository-settings
# half ported from the retired `.github-tofu` scaffold (its per-repo rulesets
# are dropped — the org rulesets in rulesets.tf already cover signed commits,
# linear history, and Conventional Commits on every repo).
#
# config/repos.yml is the single source of truth for which repos are managed
# and their per-repo metadata (visibility, description, topics). The owner is
# supplied by the single provider in providers.tf, never repeated per repo.

locals {
  # Inventory of managed repos, keyed by repo name.
  repos = yamldecode(file("${path.module}/config/repos.yml")).repos
}

module "repo_settings" {
  source   = "./modules/repo-settings"
  for_each = local.repos

  name        = each.key
  description = each.value.description
  topics      = each.value.topics
  visibility  = each.value.visibility
  # Optional — most repos.yml entries omit these, which yamldecode simply drops
  # from the map, so try() falls back to each module default (`false`).
  archived = try(each.value.archived, false)
  gitflow  = try(each.value.gitflow, false)
}

# Import-on-first-apply: adopt every managed repo (and its two Dependabot
# sub-resources) into Terraform state so the first apply RECONCILES the
# existing repos' settings instead of trying to create them — which
# prevent_destroy would block and a name collision would fail anyway. Mirrors
# what `.github-tofu/scripts/import.sh` imported, but as native Terraform 1.5+
# import blocks rather than a shell script. The import id for a
# github_repository is the bare repo name (owner comes from the provider); for
# the Dependabot sub-resources it is likewise the repo name.
#
# These blocks are idempotent and only useful once. After a successful apply
# they can be removed in a follow-up PR.
import {
  for_each = local.repos
  to       = module.repo_settings[each.key].github_repository.this
  id       = each.key
}

# The two Dependabot sub-resources are count-gated to 0 on archived repos (they
# can't be managed there), so their import targets are the [0] instance and the
# archived repos are filtered out — importing to a count=0 instance would be an
# invalid target.
import {
  for_each = { for name, cfg in local.repos : name => cfg if !try(cfg.archived, false) }
  to       = module.repo_settings[each.key].github_repository_vulnerability_alerts.this[0]
  id       = each.key
}

import {
  for_each = { for name, cfg in local.repos : name => cfg if !try(cfg.archived, false) }
  to       = module.repo_settings[each.key].github_repository_dependabot_security_updates.this[0]
  id       = each.key
}
