terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend stays commented for the first apply (no S3 bucket exists yet).
  # After `tofu apply` materializes the bucket below, uncomment and run
  # `tofu init -migrate-state` to lift the local bootstrap state into the
  # bucket it just created. From then on the bootstrap state lives at
  # `_bootstrap/terraform.tfstate` in the same bucket as the main rulesets
  # state (which lives at `github/terraform.tfstate`).
  #
  # backend "s3" {
  #   bucket       = "tfstate-github-<account-id>"
  #   key          = "_bootstrap/terraform.tfstate"
  #   region       = "us-east-2"
  #   use_lockfile = true
  #   encrypt      = true
  # }
}
