# Per-repo opt-in for deterministic (no-AI) IaC drift detection.
#
# For each repo flagged `enabled: true` in the selected per-org iac-drift.yml,
# set the Actions variable IAC_DRIFT_ENABLED=true. The ai-workflows drift caller
# gates on (`vars.IAC_DRIFT_ENABLED == 'true'`). Mirrors the ai-variables.tf opt-in shape:
# one YAML source of truth, decoded in locals.tf, fanned out to one resource here.
locals {
  iac_drift_repos = {
    for repo, cfg in local.iac_drift.repos : repo => cfg
    if try(cfg.enabled, false)
  }
}

resource "github_actions_variable" "iac_drift_enabled" {
  for_each = var.dryvist_org_extras ? local.iac_drift_repos : {}

  repository    = each.key
  variable_name = "IAC_DRIFT_ENABLED"
  value         = "true"
}
