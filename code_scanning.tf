# CodeQL default setup on every public, unarchived, non-fork repo in the org.
#
# Free: code scanning on a public repo consumes no GHAS licence, and
# runner_type = "standard" keeps the analysis on free GitHub-hosted runners.
# The search query only returns public repos, so no private repo can enter the
# set; a repo made private later drops out of it. Cost impact: $0.
#
# The provider has no resource for this API yet (upstream PR #3315 is open;
# latest release v6.13.0), so each repo's default-setup singleton is managed
# through restapi_object, the way the org rulesets are. Switch to
# github_repository_code_scanning_default_setup once it ships.
#
# Import ID is "<path>/<object id>": path ".../code-scanning", object "default-setup".
data "github_repositories" "public_for_codeql" {
  query = "org:${local.org} archived:false fork:false is:public"
}

import {
  for_each = var.codeql_import_enabled ? toset(data.github_repositories.public_for_codeql.names) : toset([])
  to       = restapi_object.codeql[each.value]
  id       = "/repos/${local.org}/${each.value}/code-scanning/default-setup"
}

resource "restapi_object" "codeql" {
  for_each = toset(data.github_repositories.public_for_codeql.names)

  path        = "/repos/${local.org}/${each.value}/code-scanning"
  object_id   = "default-setup"
  create_path = "/repos/${local.org}/${each.value}/code-scanning/default-setup"

  create_method = "PATCH"
  update_method = "PATCH"
  # A repo leaving the set (archived, made private, a search gap) keeps its scanning; destroy is a read.
  destroy_method = "GET"

  # The API adds languages, schedule, threat_model and timestamps to the response.
  ignore_server_additions = true

  data = jsonencode({
    state       = "configured"
    query_suite = "default"
    runner_type = "standard"
  })
}

# Require CodeQL on merge targets only. Default setup scans the default branch
# and protected branches, so these refs cover trunk and git-flow merge targets.
# Reuse the live public-repository set above; private, archived, and forked repos
# never receive a rule whose CodeQL analysis may not report.
resource "github_organization_ruleset" "code_scanning" {
  count = length(data.github_repositories.public_for_codeql.names) > 0 ? 1 : 0

  name        = "org-code-scanning"
  target      = "branch"
  enforcement = var.org_code_scanning_enforcement

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH", "refs/heads/main"]
      exclude = []
    }

    repository_name {
      include = sort(data.github_repositories.public_for_codeql.names)
      exclude = []
    }
  }

  rules {
    required_code_scanning {
      required_code_scanning_tool {
        alerts_threshold          = "errors"
        security_alerts_threshold = "high_or_higher"
        tool                      = "CodeQL"
      }
    }
  }
}
