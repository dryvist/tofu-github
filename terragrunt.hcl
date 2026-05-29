# Terragrunt configuration for terraform-github (dryvist org governance).
#
# Governance state is small and has no SOPS/Doppler/deployment.json layers —
# this file only wires the shared S3 remote state backend. The github provider
# reads GITHUB_TOKEN from the environment (ORG_ADMIN tier to apply).

terraform {
  source = "."
}

# Remote state backend configuration using S3 (org convention).
# The bucket name embeds the AWS account id, so it is resolved at runtime
# rather than committed.
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = "terraform-proxmox-state-useast2-${get_aws_account_id()}"
    key          = "terraform-github/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true

    # Retry configuration for transient S3 failures
    max_retries = 5
  }
}
