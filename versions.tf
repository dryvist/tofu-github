terraform {
  required_version = ">= 1.6.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  # Remote state in S3 (org convention). Backend values are supplied at init
  # time (bucket / key / region) via `-backend-config` or terragrunt and are
  # never hardcoded here, because the bucket name embeds the AWS account ID.
  # See README.md → "State". Use `tofu init -backend=false` for validation only.
  backend "s3" {}
}
