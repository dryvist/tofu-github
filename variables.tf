variable "markdown_lint_enforcement" {
  description = <<-EOT
    Enforcement mode for the org-wide markdown-lint ruleset.

    Start at "evaluate" (dry-run): the ruleset reports results in the org
    Rulesets > Insights tab WITHOUT blocking any merges. This lets the rule roll
    out across every repo safely before the whole org's markdown is compliant.
    Flip to "active" once Insights shows the fleet is green.

    One of: disabled, evaluate, active.
  EOT
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.markdown_lint_enforcement)
    error_message = "markdown_lint_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "dot_github_repository_id" {
  description = <<-EOT
    Numeric GitHub repository ID of dryvist/.github. Stable across renames;
    referenced by every org ruleset that targets a workflow living in that
    repo. Look it up with:

      gh api repos/dryvist/.github --jq .id

    Override only if the .github source-of-truth repo changes.
  EOT
  type        = number
  default     = 1220572589

  validation {
    condition     = var.dot_github_repository_id > 0
    error_message = "dot_github_repository_id must be a positive GitHub repository ID."
  }
}
