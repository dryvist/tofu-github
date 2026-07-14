# One-shot state migration for the repo rename (old name -> tofu-proxmox).
#
# The GitHub repo governed here was renamed. config/ (repos.yml, ai-callers.yml)
# already points at the new name, and GitHub carried every object (the repo,
# its develop branch + default, and all AI issue labels) across the rename.
# Terrakube STATE, however, still keys every per-repo resource under the OLD
# name. Because those resources use for_each keyed by repo name, the key change
# makes Terraform want to DESTROY the old-key instances and CREATE new-key ones.
# The live objects already exist, so they must be state-migrated, never
# destroyed and recreated.
#
# Re-adoption under the new key is handled elsewhere:
#   - the repo:   the existing `import` block in repos.tf (for_each over
#                 local.repos) adopts the renamed repo fresh -> no replace.
#   - the labels: github_issue_label upserts (adopts a same-name label instead
#                 of 422-ing; see labels.tf) -> new-key creates adopt the live
#                 labels, nothing is stripped from issues.
#   - the branch: the `import` block at the bottom of this file adopts the
#                 existing develop branch (a plain create would 422).
#
# All that remains is to FORGET the orphaned old-key state entries WITHOUT
# destroying the live objects. `removed { lifecycle { destroy = false } }` does
# exactly that -- but OpenTofu's `removed.from` cannot carry an instance key
# (opentofu/opentofu#1995), and a plain `moved` to the new key would drag the
# old ForceNew attribute values (name / repository = old name) into the new
# address and trigger a REPLACE anyway. So each orphan is first `moved` to a
# unique key-less throwaway address, then that address is `removed` with
# destroy = false. This is the documented workaround for forgetting a single
# for_each instance.
#
# These blocks are one-shot: after a clean apply they can be deleted in a
# follow-up PR, exactly like the import blocks in repos.tf.

# --- repository -------------------------------------------------------------
moved {
  from = module.repo_settings["terraform-proxmox"].github_repository.this
  to   = github_repository.rename_orphan
}
removed {
  from = github_repository.rename_orphan
  lifecycle {
    destroy = false
  }
}

# The module also has two count-gated sub-resources (vulnerability_alerts,
# dependabot_security_updates) that live in state under the old key; forget them
# too, or the orphaned module instance keeps them and they plan to destroy. The
# new-key equivalents are re-adopted by the import blocks in repos.tf.
moved {
  from = module.repo_settings["terraform-proxmox"].github_repository_vulnerability_alerts.this[0]
  to   = github_repository_vulnerability_alerts.rename_orphan
}
removed {
  from = github_repository_vulnerability_alerts.rename_orphan
  lifecycle {
    destroy = false
  }
}

moved {
  from = module.repo_settings["terraform-proxmox"].github_repository_dependabot_security_updates.this[0]
  to   = github_repository_dependabot_security_updates.rename_orphan
}
removed {
  from = github_repository_dependabot_security_updates.rename_orphan
  lifecycle {
    destroy = false
  }
}

# --- develop branch + default ----------------------------------------------
moved {
  from = github_branch.develop["terraform-proxmox"]
  to   = github_branch.rename_orphan
}
removed {
  from = github_branch.rename_orphan
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_branch_default.develop["terraform-proxmox"]
  to   = github_branch_default.rename_orphan
}
removed {
  from = github_branch_default.rename_orphan
  lifecycle {
    destroy = false
  }
}

# --- AI issue labels (21) ---------------------------------------------------
moved {
  from = github_issue_label.ai["terraform-proxmox/ai:created"]
  to   = github_issue_label.rename_orphan_ai_created
}
removed {
  from = github_issue_label.rename_orphan_ai_created
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/ai:ready"]
  to   = github_issue_label.rename_orphan_ai_ready
}
removed {
  from = github_issue_label.rename_orphan_ai_ready
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/priority:critical"]
  to   = github_issue_label.rename_orphan_priority_critical
}
removed {
  from = github_issue_label.rename_orphan_priority_critical
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/priority:high"]
  to   = github_issue_label.rename_orphan_priority_high
}
removed {
  from = github_issue_label.rename_orphan_priority_high
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/priority:low"]
  to   = github_issue_label.rename_orphan_priority_low
}
removed {
  from = github_issue_label.rename_orphan_priority_low
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/priority:medium"]
  to   = github_issue_label.rename_orphan_priority_medium
}
removed {
  from = github_issue_label.rename_orphan_priority_medium
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/size:l"]
  to   = github_issue_label.rename_orphan_size_l
}
removed {
  from = github_issue_label.rename_orphan_size_l
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/size:m"]
  to   = github_issue_label.rename_orphan_size_m
}
removed {
  from = github_issue_label.rename_orphan_size_m
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/size:s"]
  to   = github_issue_label.rename_orphan_size_s
}
removed {
  from = github_issue_label.rename_orphan_size_s
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/size:xl"]
  to   = github_issue_label.rename_orphan_size_xl
}
removed {
  from = github_issue_label.rename_orphan_size_xl
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/size:xs"]
  to   = github_issue_label.rename_orphan_size_xs
}
removed {
  from = github_issue_label.rename_orphan_size_xs
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/type:breaking"]
  to   = github_issue_label.rename_orphan_type_breaking
}
removed {
  from = github_issue_label.rename_orphan_type_breaking
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/type:bug"]
  to   = github_issue_label.rename_orphan_type_bug
}
removed {
  from = github_issue_label.rename_orphan_type_bug
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/type:chore"]
  to   = github_issue_label.rename_orphan_type_chore
}
removed {
  from = github_issue_label.rename_orphan_type_chore
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/type:ci"]
  to   = github_issue_label.rename_orphan_type_ci
}
removed {
  from = github_issue_label.rename_orphan_type_ci
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/type:docs"]
  to   = github_issue_label.rename_orphan_type_docs
}
removed {
  from = github_issue_label.rename_orphan_type_docs
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/type:feature"]
  to   = github_issue_label.rename_orphan_type_feature
}
removed {
  from = github_issue_label.rename_orphan_type_feature
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/type:perf"]
  to   = github_issue_label.rename_orphan_type_perf
}
removed {
  from = github_issue_label.rename_orphan_type_perf
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/type:refactor"]
  to   = github_issue_label.rename_orphan_type_refactor
}
removed {
  from = github_issue_label.rename_orphan_type_refactor
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/type:security"]
  to   = github_issue_label.rename_orphan_type_security
}
removed {
  from = github_issue_label.rename_orphan_type_security
  lifecycle {
    destroy = false
  }
}

moved {
  from = github_issue_label.ai["terraform-proxmox/type:test"]
  to   = github_issue_label.rename_orphan_type_test
}
removed {
  from = github_issue_label.rename_orphan_type_test
  lifecycle {
    destroy = false
  }
}

# --- re-adopt the new-key develop branch ------------------------------------
# github_branch only CREATES; the branch already exists under the renamed repo,
# so a create would 422. Import adopts it instead. github_branch_default is
# idempotent and re-asserts on its own, so it needs no import.
import {
  to = github_branch.develop["tofu-proxmox"]
  id = "tofu-proxmox:develop"
}

# --- re-adopt the new-key AI issue labels -----------------------------------
# github_issue_label CREATE does a plain POST and 422s ("already_exists") on a
# label that already exists -- it does NOT upsert. The 21 labels carried across
# the rename are live but, after the old-key forgets above, unmanaged. Import
# adopts each under the new key instead of failing to create it.
import {
  to = github_issue_label.ai["tofu-proxmox/ai:created"]
  id = "tofu-proxmox:ai:created"
}

import {
  to = github_issue_label.ai["tofu-proxmox/ai:ready"]
  id = "tofu-proxmox:ai:ready"
}

import {
  to = github_issue_label.ai["tofu-proxmox/priority:critical"]
  id = "tofu-proxmox:priority:critical"
}

import {
  to = github_issue_label.ai["tofu-proxmox/priority:high"]
  id = "tofu-proxmox:priority:high"
}

import {
  to = github_issue_label.ai["tofu-proxmox/priority:low"]
  id = "tofu-proxmox:priority:low"
}

import {
  to = github_issue_label.ai["tofu-proxmox/priority:medium"]
  id = "tofu-proxmox:priority:medium"
}

import {
  to = github_issue_label.ai["tofu-proxmox/size:l"]
  id = "tofu-proxmox:size:l"
}

import {
  to = github_issue_label.ai["tofu-proxmox/size:m"]
  id = "tofu-proxmox:size:m"
}

import {
  to = github_issue_label.ai["tofu-proxmox/size:s"]
  id = "tofu-proxmox:size:s"
}

import {
  to = github_issue_label.ai["tofu-proxmox/size:xl"]
  id = "tofu-proxmox:size:xl"
}

import {
  to = github_issue_label.ai["tofu-proxmox/size:xs"]
  id = "tofu-proxmox:size:xs"
}

import {
  to = github_issue_label.ai["tofu-proxmox/type:breaking"]
  id = "tofu-proxmox:type:breaking"
}

import {
  to = github_issue_label.ai["tofu-proxmox/type:bug"]
  id = "tofu-proxmox:type:bug"
}

import {
  to = github_issue_label.ai["tofu-proxmox/type:chore"]
  id = "tofu-proxmox:type:chore"
}

import {
  to = github_issue_label.ai["tofu-proxmox/type:ci"]
  id = "tofu-proxmox:type:ci"
}

import {
  to = github_issue_label.ai["tofu-proxmox/type:docs"]
  id = "tofu-proxmox:type:docs"
}

import {
  to = github_issue_label.ai["tofu-proxmox/type:feature"]
  id = "tofu-proxmox:type:feature"
}

import {
  to = github_issue_label.ai["tofu-proxmox/type:perf"]
  id = "tofu-proxmox:type:perf"
}

import {
  to = github_issue_label.ai["tofu-proxmox/type:refactor"]
  id = "tofu-proxmox:type:refactor"
}

import {
  to = github_issue_label.ai["tofu-proxmox/type:security"]
  id = "tofu-proxmox:type:security"
}

import {
  to = github_issue_label.ai["tofu-proxmox/type:test"]
  id = "tofu-proxmox:type:test"
}

