# Per-repo opt-in for deterministic (no-AI) IaC drift detection.
#
# For each repo flagged `enabled: true` in config/iac-drift.yml, set the Actions
# variable IAC_DRIFT_ENABLED=true — the gate the ai-workflows drift caller checks
# (`vars.IAC_DRIFT_ENABLED == 'true'`). Mirrors the ai-variables.tf opt-in shape:
# one YAML source of truth, decoded in locals.tf, fanned out to one resource here.
locals {
  iac_drift_repos = {
    for repo, cfg in local.iac_drift.repos : repo => cfg
    if try(cfg.enabled, false)
  }
}

resource "github_actions_variable" "iac_drift" {
  for_each = local.iac_drift_repos

  repository    = each.key
  variable_name = "IAC_DRIFT_ENABLED"
  value         = "true"
}

# The resource was renamed from iac_drift_enabled when terraform-proxmox became
# tofu-proxmox: the old state key named the old repository, and the provider
# replaces a variable whose repository changes. Forget the old resource without
# deleting the live variables and adopt them under the new name. An import whose
# target is already in state is a no-op.
removed {
  from = github_actions_variable.iac_drift_enabled

  lifecycle {
    destroy = false
  }
}

import {
  for_each = local.iac_drift_repos
  to       = github_actions_variable.iac_drift[each.key]
  id       = "${each.key}:IAC_DRIFT_ENABLED"
}
