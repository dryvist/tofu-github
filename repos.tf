# Per-repo settings for the repos this config governs. The repository-settings
# half ported from the retired `.github-tofu` scaffold (its per-repo rulesets
# are dropped — the org rulesets in rulesets.tf already cover signed commits and
# Conventional Commits on every repo).
#
# config/repos.yml is the single source of truth for which repos are managed
# and their per-repo metadata (visibility, description, topics). The owner is
# supplied by the single provider in providers.tf, never repeated per repo.

locals {
  # Inventory of managed repos, keyed by repo name.
  repos = yamldecode(file("${path.module}/config/repos.yml")).repos

  # The set this config actually governs.
  #
  # Default (var.manage_all_repos = false): exactly the repos listed above.
  # That opt-in model is why repos in this org are born ungoverned — org
  # rulesets bind every repo automatically, but repo SETTINGS reach only the
  # ones someone remembered to list, and most of the org is not listed.
  #
  # Flipping the flag unions the live org enumeration under the config,
  # inverting the default to managed-unless-excluded. Enumerated repos inherit
  # their live description/topics/visibility (so nothing is blanked) and derive
  # git-flow from their default branch; a config/repos.yml entry always wins
  # wholesale, which also keeps archived repos — absent from the enumeration —
  # under management.
  managed_repos = var.manage_all_repos ? merge({
    for name, repo in data.github_repository.enumerated : name => {
      visibility  = repo.visibility
      description = repo.description
      topics      = repo.topics
      gitflow     = repo.default_branch == "develop"
    }
  }, local.repos) : local.repos

  # Managed repos that already exist on GitHub, and are therefore ADOPTED by
  # the import blocks below rather than created. The complement — a
  # config/repos.yml entry naming a repo that does not exist yet — is simply
  # created, because an import aimed at it would fail the plan with "Cannot
  # import non-existent remote object".
  #
  # Derived from the live org (data.github_repositories.existing), never from
  # a per-repo flag. A flag would encode how a repo came to be, which is true
  # exactly once and then becomes a lie the config keeps telling; this asks
  # GitHub, so the same entry stays correct before creation and forever after.
  # An import block whose resource is already in state is a no-op, so a repo
  # created by one apply is harmlessly re-listed here on the next.
  adopted_repos = {
    for name, cfg in local.managed_repos : name => cfg
    if contains(data.github_repositories.existing.names, name)
  }
}

module "repo_settings" {
  source   = "./modules/repo-settings"
  for_each = local.managed_repos

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
  for_each = local.adopted_repos
  to       = module.repo_settings[each.key].github_repository.this
  id       = each.key
}

# The two Dependabot sub-resources are count-gated to 0 on archived repos (they
# can't be managed there), so their import targets are the [0] instance and the
# archived repos are filtered out — importing to a count=0 instance would be an
# invalid target.
import {
  for_each = { for name, cfg in local.adopted_repos : name => cfg if !try(cfg.archived, false) }
  to       = module.repo_settings[each.key].github_repository_vulnerability_alerts.this[0]
  id       = each.key
}

import {
  for_each = { for name, cfg in local.adopted_repos : name => cfg if !try(cfg.archived, false) }
  to       = module.repo_settings[each.key].github_repository_dependabot_security_updates.this[0]
  id       = each.key
}
