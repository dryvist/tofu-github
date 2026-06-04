# CodeQL default-setup — pending upstream provider support.
#
# Code scanning default-setup is FREE on public repos (no GHAS license
# consumed). Enabling it across every public org repo with a supported
# language is the goal; this file is the placeholder that becomes the
# canonical config once integrations/terraform-provider-github exposes the
# resource.
#
# Status as of 2026-06-04: the resource does NOT exist in the provider yet.
# `integrations/github` ~> 6.0's `security_and_analysis` block covers
# advanced_security, code_security (paid GHAS), secret_scanning, push
# protection, AI detection, and non-provider patterns — but not the free
# CodeQL default-setup endpoint.
#
# Upstream: https://github.com/integrations/terraform-provider-github/pull/3315
# (feat: Add github_repository_code_scanning_default_setup resource).
# Opened 2026-04-01 by oda251. Adds the resource with the schema below.
#
# When that PR merges and ships in a tagged release:
#
#   1. Bump `version = "~> 6.X"` in versions.tf to the release that includes it.
#   2. Uncomment the data + resource blocks below.
#   3. `tofu apply` — for_each fans out across every public, non-archived,
#      non-fork org repo. The provider's underlying API will return success
#      on repos with a supported language and a clear error on repos
#      without one; refine the query if necessary, or filter via a follow-up
#      data lookup once the provider exposes `languages` reliably.
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
