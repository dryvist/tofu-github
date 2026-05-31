variable "github_org" {
  description = <<-EOT
    GitHub org login that owns the consuming repo. Pinned into the
    OIDC trust subject of the bootstrapped role. Required, no default —
    operator supplies via tfvars or `-var` at apply time so the source
    tree stays identity-free.
  EOT
  type        = string

  validation {
    condition     = length(var.github_org) > 0
    error_message = "github_org must be a non-empty GitHub org login."
  }
}

variable "github_repo" {
  description = <<-EOT
    Name of the consuming repo. Pinned into the OIDC trust subject so the
    role can only be assumed by GitHub Actions runs of this specific repo.
    Required, no default.
  EOT
  type        = string

  validation {
    condition     = length(var.github_repo) > 0
    error_message = "github_repo must be a non-empty repo name."
  }
}

variable "operator_user_arns" {
  description = <<-EOT
    IAM user ARNs allowed to assume the bootstrapped role with MFA from
    local dev shells. Required, no default — operator supplies via
    tfvars at apply time. Empty list disables operator AssumeRole
    entirely (CI-only operation).
  EOT
  type        = list(string)

  validation {
    condition     = alltrue([for a in var.operator_user_arns : can(regex("^arn:aws:iam::[0-9]{12}:user/", a))])
    error_message = "Each operator_user_arns entry must be an IAM user ARN (arn:aws:iam::<account>:user/<name>)."
  }
}

variable "aws_region" {
  description = <<-EOT
    Region for the state bucket. Matches the existing org convention
    (us-east-2) used by sibling state buckets in this account.
  EOT
  type        = string
  default     = "us-east-2"
}

variable "branch_pattern" {
  description = <<-EOT
    Branch name pattern (StringLike against the OIDC sub claim) that
    CI is allowed to assume the role from on push events. Default
    `main` matches the consuming repo's default branch.
  EOT
  type        = string
  default     = "main"
}
