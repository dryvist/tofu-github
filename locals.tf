# Structured defaults consumed by org rulesets live in config/*.yml; this
# file decodes them into named locals so rulesets.tf reads them as terraform
# values, not raw file reads scattered through resource bodies.
locals {
  # The org login, recovered from the `.github` repo's full_name rather than
  # written down. The provider's `owner` decides which org that resolves to.
  org = split("/", data.github_repository.dot_github.full_name)[0]

  rulesets_defaults = yamldecode(file("${path.module}/config/rulesets-defaults.yml"))
  docs_publisher    = yamldecode(file("${path.module}/config/docs-publisher.yml"))

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
  # from config/merge-gate.yml and consumed by merge-gate.tf.
  merge_gate_contexts = yamldecode(file("${path.module}/config/merge-gate.yml")).merge_gate.contexts

  # Copilot code-review pilot targets: branch -> explicit repo list,
  # decoded from config/copilot-review.yml and consumed by copilot-review.tf.
  copilot_review_targets = yamldecode(file("${path.module}/config/copilot-review.yml")).copilot_review

  # IaC drift-detection opt-in: repos flagged enabled get IAC_DRIFT_ENABLED=true.
  # Consumed by iac-drift.tf. See config/iac-drift.yml.
  iac_drift = yamldecode(file("${path.module}/config/iac-drift.yml"))
}
