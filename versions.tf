terraform {
  # >= 1.10 required for S3 native locking (`use_lockfile = true` in
  # terragrunt.hcl). Earlier versions ignore the option and run unlocked.
  required_version = ">= 1.10"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  # Remote state in S3. Backend values come from terragrunt.hcl
  # (`tfstate-github-<account>` / `github/terraform.tfstate` / us-east-2)
  # so no bucket name is committed here. Use `tofu init -backend=false`
  # for validation-only runs.
  backend "s3" {}
}
