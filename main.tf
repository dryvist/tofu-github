# Multi-file root configuration. Resources are organized by topic in named
# .tf files rather than concentrated here:
#
#   rulesets.tf    — github_organization_ruleset.*
#   (future)       — repo_files.tf (github_repository_file.*)
#
# main.tf is the entrypoint required by tflint's standard-module-structure
# check. As top-level orchestration grows (e.g. a shared data lookup the
# topical files reference), it lands here. Until then, it's intentionally
# resource-free.
