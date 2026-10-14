# Shared defaults and per-org policy config are decoded into named locals so
# resources read Terraform values rather than scattering file reads in bodies.
locals {
  org_config_dir = var.config_org == "" ? "config" : "config/orgs/${var.config_org}"

  # The org login, recovered from the `.github` repo's full_name rather than
  # written down. The provider's `owner` decides which org that resolves to.
  org = split("/", data.github_repository.dot_github.full_name)[0]

  release_app_ids = [
    for variable in data.github_actions_organization_variables.org.variables : tonumber(trimspace(variable.value))
    if variable.name == "GH_ACTION_RELEASE_PLEASE_APP_ID" && trimspace(variable.value) != ""
  ]

  rulesets_defaults = yamldecode(file("${path.module}/config/rulesets-defaults.yml"))
  docs_publisher    = yamldecode(file("${path.module}/${local.org_config_dir}/docs-publisher.yml"))

  ruleset_imports            = local.rulesets_defaults.imports
  push_protection_defaults   = local.rulesets_defaults.push_protection
  branch_protection_defaults = local.rulesets_defaults.branch_protection
  gitflow_defaults           = local.rulesets_defaults.gitflow
  upstream_fork_defaults     = local.rulesets_defaults.upstream_fork

  # Strict Conventional Commits regex on the subject line: the v1.0.0 type
  # set, an optional lowercase alphanumeric + hyphen scope, `!` for a breaking
  # change, anchored at the start only so a body and trailers may follow. The
  # file is the single copy; local commit-msg hooks read it too.
  commit_message_pattern = trimspace(file("${path.module}/config/commit-message-pattern.txt"))

  # Git-flow variant: back-merges and release merges land "Merge branch ..." /
  # "Merge pull request ..." subjects, so a leading "Merge " alternation wraps
  # the same pattern.
  gitflow_commit_message_pattern = "^(Merge .+|${trimprefix(local.commit_message_pattern, "^")})"

  # Merge Gate required-check inventory: check context per repo group, decoded
  # from the selected per-org merge-gate.yml and consumed by merge-gate.tf.
  merge_gate_contexts = yamldecode(file("${path.module}/${local.org_config_dir}/merge-gate.yml")).merge_gate.contexts

  # Copilot code-review pilot targets: branch -> explicit repo list, decoded
  # from the selected per-org copilot-review.yml and consumed by copilot-review.tf.
  copilot_review_targets = yamldecode(file("${path.module}/${local.org_config_dir}/copilot-review.yml")).copilot_review

  # IaC drift-detection opt-in: repos flagged enabled get IAC_DRIFT_ENABLED=true.
  # Consumed by iac-drift.tf. See the selected per-org iac-drift.yml.
  iac_drift = yamldecode(file("${path.module}/${local.org_config_dir}/iac-drift.yml"))
}
