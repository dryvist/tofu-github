# No outputs exposed at the root level. The side effects of `tofu apply` are
# the org-level rulesets, repo files, and settings created on GitHub
# directly — they're not consumable as Terraform outputs by callers. The
# standard-module-structure check requires this file to exist; per the
# check's own warning text, an empty outputs.tf is valid.
