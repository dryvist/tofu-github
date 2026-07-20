# Structured defaults consumed by org rulesets live in config/*.yml; this
# file decodes them into named locals so rulesets.tf reads them as terraform
# values, not raw file reads scattered through resource bodies.
locals {
  # The org login, recovered from the `.github` repo's full_name rather than
  # written down. The provider's `owner` decides which org that resolves to.
  org = split("/", data.github_repository.dot_github.full_name)[0]

  rulesets_defaults = yamldecode(file("${path.module}/config/rulesets-defaults.yml"))

  ruleset_imports            = local.rulesets_defaults.imports
  push_protection_defaults   = local.rulesets_defaults.push_protection
  branch_protection_defaults = local.rulesets_defaults.branch_protection
  gitflow_defaults           = local.rulesets_defaults.gitflow


  # AI caller-workflow rollout config: opted-in repos (per-repo params) plus the
  # shared label taxonomy. Consumed by labels.tf. Single source of
  # truth for which repos are in the AI chain.
  ai = yamldecode(file("${path.module}/config/ai-callers.yml"))

  # Merge Gate required-check inventory: check context per repo group, decoded
  # from config/merge-gate.yml and consumed by merge-gate.tf.
  merge_gate_contexts = yamldecode(file("${path.module}/config/merge-gate.yml")).merge_gate.contexts

  # Copilot code-review pilot targets: branch -> explicit repo list,
  # decoded from config/copilot-review.yml and consumed by copilot-review.tf.
  copilot_review_targets = yamldecode(file("${path.module}/config/copilot-review.yml")).copilot_review
}
