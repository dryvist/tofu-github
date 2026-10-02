# One-shot state migration for the repo rename (old name -> tofu-proxmox).
#
# The GitHub repo governed here was renamed. config/repos.yml
# already points at the new name, and GitHub carried every object (the repo,
# its develop branch + default) across the rename.
# Terrakube STATE, however, still keys every per-repo resource under the OLD
# name. Because those resources use for_each keyed by repo name, the key change
# makes Terraform want to DESTROY the old-key instances and CREATE new-key ones.
# The live objects already exist, so they must be state-migrated, never
# destroyed and recreated.
#
# Re-adoption under the new key is handled elsewhere:
#   - the repo:   the existing `import` block in repos.tf (for_each over
#                 local.repos) adopts the renamed repo fresh -> no replace.
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
