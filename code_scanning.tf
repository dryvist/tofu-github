# CodeQL default-setup — manually bootstrapped, pending provider support for IaC adoption.
#
# Code scanning default-setup is FREE on public repos (no GHAS license
# consumed) and is the chosen mechanism for org-wide code scanning.
#
# CURRENT STATE (2026-06-28): default setup is ENABLED on every public org repo
# (31 repos), bootstrapped manually via the code-scanning default-setup API
# because the Terraform provider does not expose the resource yet. This file
# becomes the canonical config — by IMPORT, not create — once the provider ships.
#
# RE-VALIDATED 2026-07-28 against v6.13.0 (latest, published 2026-07-08) —
# not against this comment's prior claim. The registry's resource index for
# 6.13.0 lists 88 resources and ZERO matching /scan/; the only adjacent one is
# `enterprise_security_analysis_settings`, which is enterprise-scoped and does
# not reach a repo's CodeQL default setup. Both upstream PRs are still OPEN:
#   - github_repository_code_scanning_default_setup (PR #3315, last touched
#     2026-06-03)
#   - github_organization_security_configuration     (PR #3284, last touched
#     2026-07-24)
# `integrations/github` ~> 6.0's `security_and_analysis` block covers
# secret_scanning + push protection (free on public, used in
# modules/repo-settings) but NOT the free CodeQL default-setup endpoint.
#
# CONSEQUENCE FOR NEW REPOS: a repo created by this config (`create: true` in
# config/repos.yml) lands WITHOUT code scanning. Until the provider ships,
# enabling it is a manual step — the same one-off the other 31 repos went
# through. Tracked in Vikunja so it is not lost between the two events
# (repo creation now, provider support later).
#
# Upstream: https://github.com/integrations/terraform-provider-github/pull/3315
# (feat: Add github_repository_code_scanning_default_setup resource).
#
# When that PR merges and ships in a tagged release:
#
#   1. Bump `version = "~> 6.X"` in versions.tf to the release that includes it.
#   2. Uncomment the data + resource + import blocks below.
#   3. `tofu plan` should show the import ADOPTING the already-enabled repos
#      with no resource changes (the manual bootstrap used state=configured,
#      query_suite=default — keep those matched here). `tofu apply` writes
#      state. Adjust query_suite/languages only if a plan diff appears.
#
# Cost impact (per AGENTS.md "Cost policy"): $0. Code scanning is FREE on
# public repos and the data source's `visibility:public` filter is the safety
# belt — no private repo can land in the for_each.
#
# data "github_repositories" "public_for_codeql" {
#   query = "org:dryvist archived:false fork:false visibility:public"
# }
#
# resource "github_repository_code_scanning_default_setup" "codeql" {
#   for_each = toset(data.github_repositories.public_for_codeql.names)
#
#   repository  = each.value
#   state       = "configured"
#   query_suite = "default"
#
#   # `languages` is Optional/Computed in the upstream schema — let the
#   # provider auto-detect from the repo's contents. Set explicitly only
#   # for repos where a subset is desired.
# }
#
# # Adopt the manually-enabled default setups into state (ADOPT, do not
# # re-create). Requires Terraform >= 1.7 for for_each in import blocks; this
# # repo already pins >= 1.10. Confirm the import ID format against the shipped
# # provider docs (expected: the repository name).
# import {
#   for_each = toset(data.github_repositories.public_for_codeql.names)
#   to       = github_repository_code_scanning_default_setup.codeql[each.value]
#   id       = each.value
# }
