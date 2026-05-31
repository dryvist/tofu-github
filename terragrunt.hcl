# Terragrunt configuration for the org governance stack.
#
# State backend is this stack's own dedicated S3 bucket, provisioned once by
# `bootstrap/` calling the terraform-aws-template module. Bucket and role
# naming follow the template's formula (`tfstate-${project}-${account}` and
# `tf-${project}` with `project = "github"`). The bucket name embeds the AWS
# account id, resolved at runtime via `get_aws_account_id()` so no account
# identifier is committed.
#
# Apply requires assumed-role STS credentials from the `tf-github` role
# (operator: `aws-vault exec tf-github`; CI: `aws-actions/configure-aws-credentials@v4`
# with the role ARN). The github provider reads `GITHUB_TOKEN` separately —
# ORG_ADMIN tier to apply org-level rulesets.

terraform {
  source = "."
}

# Remote state backend.
# S3 native locking (`use_lockfile = true`) — no DynamoDB table needed.
# Requires OpenTofu/Terraform >= 1.10 (declared in versions.tf).
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = "tfstate-github-${get_aws_account_id()}"
    key          = "github/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true

    # Retry configuration for transient S3 failures.
    max_retries = 5
  }
}
