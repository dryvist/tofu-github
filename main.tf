# Multi-file root configuration. Resources are organized by topic in named
# .tf files rather than concentrated here:
#
#   rulesets-push-protection.tf     — github_organization_ruleset.org_push_protection
#   actions.tf                      — organization Actions permissions
#   rulesets-branch-protection.tf   — restapi_object.{org_branch_protection,org_review_gate} + github_organization_ruleset.{required_signatures,commit_subject_branches}
#   rulesets-gitflow.tf             — github_organization_ruleset.org_gitflow_base + restapi_object.{org_gitflow_main,org_gitflow_develop}
#   upstream-forks.tf               — upstream_fork property + restapi_object.org_upstream_fork_protection
#   (future)                        — repo_files.tf (github_repository_file.*)
#
# main.tf is the entrypoint required by tflint's standard-module-structure
# check. As top-level orchestration grows (e.g. a shared data lookup the
# topical files reference), it lands here. Until then, it's intentionally
# resource-free.
