# Structured defaults consumed by org rulesets live in config/*.yml; this
# file decodes them into named locals so rulesets.tf reads them as terraform
# values, not raw file reads scattered through resource bodies.
locals {
  rulesets_defaults = yamldecode(file("${path.module}/config/rulesets-defaults.yml"))

  ruleset_imports            = local.rulesets_defaults.imports
  push_protection_defaults   = local.rulesets_defaults.push_protection
  branch_protection_defaults = local.rulesets_defaults.branch_protection
  gitflow_defaults           = local.rulesets_defaults.gitflow

  # Org-level Actions variables, decoded from config/actions-variables.yml so
  # org_settings.tf carries no inline values.
  ai_model_variables = yamldecode(file("${path.module}/config/actions-variables.yml")).ai_models

  # AI caller-workflow rollout config: opted-in repos (per-repo params) plus the
  # shared label taxonomy. Consumed by labels.tf and ai-variables.tf. Single source of
  # truth for which repos are in the AI chain.
  ai = yamldecode(file("${path.module}/config/ai-callers.yml"))
}
