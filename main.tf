# Multi-file root configuration. Resources are organized by topic in named
# .tf files rather than concentrated here:
#
#   rulesets.tf    — github_organization_ruleset.*
#   (future)       — org_settings.tf (github_actions_organization_*),
#                    repo_files.tf (github_repository_file.*),
#                    labels.tf (github_issue_labels.*)
#
# main.tf is the entrypoint required by tflint's standard-module-structure
# check. As top-level orchestration grows (e.g. a shared data lookup the
# topical files reference), it lands here. Until then, it's intentionally
# resource-free.
