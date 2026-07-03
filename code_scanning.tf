# CodeQL default-setup — manually bootstrapped, pending provider support for IaC adoption.
#
# Code scanning default-setup is FREE on public repos (no GHAS license
# consumed) and is the chosen mechanism for org-wide code scanning.
#
# CURRENT STATE (2026-07-03): default setup is ENABLED on every public org repo
# (31 repos), bootstrapped manually via the code-scanning default-setup API
# because the Terraform provider does not expose the resource yet. This file
# becomes the canonical config — by IMPORT, not create — once the provider ships.
#
# QUERY SUITE STANDARD = `default` (NOT `extended`). The extended suite pulls in
# extended-only queries — notably `actions/unpinned-tag`, which flags every
# third-party action pinned to a version tag. Org policy deliberately KEEPS
# well-known trusted actions on major tags (see each repo's `.github/zizmor.yml`
# `unpinned-uses: disable`), so `extended` generates systematic, unactionable
# noise across every public repo. The `default` suite omits it; the pre-commit
# stack (zizmor, OSV, semgrep, gitleaks) covers the remaining extended gap.
#
# DRIFT (2026-07-03): the original manual bootstrap set `query_suite=extended`,
# so all 31 public repos currently run `extended` and surface `actions/unpinned-tag`
# alerts. Re-bootstrap them to `default` to match this standard (idempotent):
#
#   for r in $(gh api graphql -f query='{organization(login:"dryvist"){repositories(first:100,privacy:PUBLIC){nodes{name isArchived isFork}}}}' \
#       --jq '.data.organization.repositories.nodes[]|select(.isArchived==false and .isFork==false)|.name'); do
#     gh api -X PATCH "repos/dryvist/$r/code-scanning/default-setup" \
#       -f state=configured -f query_suite=default >/dev/null 2>&1 \
#       && echo "ok: $r" || echo "skip: $r"
#   done
#
# Needs an ORG_ADMIN-tier token (security_events / repo admin). Run once; the
# import block below then adopts the aligned state when the provider ships.
#
# Why not Terraform yet: as of provider v6.12.1, neither
#   - github_repository_code_scanning_default_setup (PR #3315, OPEN), nor
#   - github_organization_security_configuration     (PR #3284, OPEN)
# exists in a tagged release. `integrations/github` ~> 6.0's
# `security_and_analysis` block covers secret_scanning + push protection (free
# on public, used in modules/repo-settings) but NOT the free CodeQL
# default-setup endpoint.
#
# Upstream: https://github.com/integrations/terraform-provider-github/pull/3315
# (feat: Add github_repository_code_scanning_default_setup resource).
#
# When that PR merges and ships in a tagged release:
#
#   1. Bump `version = "~> 6.X"` in versions.tf to the release that includes it.
#   2. Uncomment the data + resource + import blocks below.
#   3. `tofu plan` should show the import ADOPTING the already-enabled repos
#      with no resource changes, PROVIDED the re-bootstrap above has aligned
#      them to state=configured, query_suite=default (the standard). `tofu apply`
#      writes state. Adjust query_suite/languages only if a plan diff appears.
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
