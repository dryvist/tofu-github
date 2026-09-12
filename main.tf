# Multi-file root configuration. Resources are organized by topic in named
# .tf files rather than concentrated here:
#
#   rulesets-push-protection.tf     — github_organization_ruleset.org_push_protection
#   rulesets-branch-protection.tf   — github_organization_ruleset.{org_branch_protection,required_signatures,org_review_gate}
#   rulesets-required-workflows.tf  — github_organization_ruleset.{markdown_lint,conventions}
#   rulesets-gitflow.tf             — github_organization_ruleset.org_gitflow_*
#   (future)                        — repo_files.tf (github_repository_file.*)
#
# main.tf is the entrypoint required by tflint's standard-module-structure
# check. As top-level orchestration grows (e.g. a shared data lookup the
# topical files reference), it lands here. Until then, it's intentionally
# resource-free.
