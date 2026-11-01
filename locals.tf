# Shared defaults and optional organization config are decoded into named
# locals so resources read Terraform values rather than scattering file reads.
locals {
  org_config_dir = "${path.module}/config/orgs/${var.github_owner}"

  org = var.github_owner

  release_app_ids = [
    for variable in data.github_actions_organization_variables.org.variables : tonumber(trimspace(variable.value))
    if variable.name == "GH_ACTION_RELEASE_PLEASE_APP_ID" && trimspace(variable.value) != ""
  ]

  rulesets_defaults = yamldecode(file("${path.module}/config/rulesets-defaults.yml"))
  central           = yamldecode(file("${path.module}/config/central.yml"))
  ruleset_imports   = try(yamldecode(file("${local.org_config_dir}/ruleset-imports.yml")).imports, {})
  actions_defaults  = local.rulesets_defaults.actions
  repos_config      = try(yamldecode(file("${local.org_config_dir}/repos.yml")), {})
  automerge_config = try(yamldecode(file("${local.org_config_dir}/automerge.yml")), {
    manual = { prefixes = [], repos = [] }
  })
  ai_untrusted_config = try(yamldecode(file("${local.org_config_dir}/ai-untrusted.yml")), {
    repos = []
  })
  docs_publisher = try(yamldecode(file("${local.org_config_dir}/docs-publisher.yml")), {})

  org_merge_gate_contexts = try(yamldecode(file("${local.org_config_dir}/merge-gate.yml")).merge_gate.contexts, {})
  # An org whose gates include private repos fails its plan when the private overrides are missing.
  merge_gate_requires_private_repos = try(yamldecode(file("${local.org_config_dir}/merge-gate.yml")).merge_gate.requires_private_repos, false)
  # Repo metadata is not a credential; its names must be usable as managed-resource keys.
  private_repo_overrides = local.merge_gate_requires_private_repos ? try(
    nonsensitive(jsondecode(data.vault_kv_secret_v2.private_repo_overrides[0].data_json).private_repo_overrides),
    {},
  ) : {}
  # One entry per (private repo, gate); concatenated into the org gate of the same key below.
  private_merge_gate_entries = flatten([
    for repo, cfg in local.private_repo_overrides : [
      for key, gate in try(cfg.merge_gate, {}) : { key = key, context = gate.context, repo = repo }
    ]
  ])
  merge_gate_contexts = {
    for key in distinct(concat(keys(local.org_merge_gate_contexts), local.private_merge_gate_entries[*].key)) : key => {
      context = try(local.org_merge_gate_contexts[key].context, [for e in local.private_merge_gate_entries : e.context if e.key == key][0])
      repos = sort(distinct(concat(
        try(local.org_merge_gate_contexts[key].repos, []),
        [for e in local.private_merge_gate_entries : e.repo if e.key == key],
      )))
    }
  }
  copilot_review_targets = try(yamldecode(file("${local.org_config_dir}/copilot-review.yml")).copilot_review, {})
  iac_drift              = try(yamldecode(file("${local.org_config_dir}/iac-drift.yml")), { repos = {} })

  push_protection_defaults   = local.rulesets_defaults.push_protection
  branch_protection_defaults = local.rulesets_defaults.branch_protection
  gitflow_defaults           = local.rulesets_defaults.gitflow
  upstream_fork_defaults     = local.rulesets_defaults.upstream_fork
  # required_reviewers matches the server's default so plans stay empty.
  pull_request_rule_base = {
    require_extra_approval_for_unattributed_changes = false
    required_reviewers                              = []
  }

  # Strict Conventional Commits regex on the subject line: the v1.0.0 type
  # set, an optional lowercase alphanumeric + hyphen scope, `!` for a breaking
  # change, anchored at the start only so a body and trailers may follow. The
  # file is the single copy; local commit-msg hooks read it too.
  commit_message_pattern = trimspace(file("${path.module}/config/commit-message-pattern.txt"))

  # Git-flow variant: back-merges and release merges land "Merge branch ..." /
  # "Merge pull request ..." subjects, so a leading "Merge " alternation wraps
  # the same pattern.
  gitflow_commit_message_pattern = "^(Merge .+|${trimprefix(local.commit_message_pattern, "^")})"
}
