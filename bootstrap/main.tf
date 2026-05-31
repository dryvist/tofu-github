# GitHub Actions OIDC provider — prerequisite for the IAM role's OIDC
# trust statement. Account-wide singleton: one provider per AWS account
# serves every GitHub repo that needs OIDC. If another stack in this
# account already created this provider, this resource's create will
# fail with "EntityAlreadyExists"; resolve by importing once:
#
#   tofu import aws_iam_openid_connect_provider.github \
#     arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com
#
# Then re-run apply. Subsequent applies are no-ops on this resource.
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# State backend + scoped IAM role, provisioned via the canonical template.
# Project name is intentionally short ("github") — the template derives
# the bucket name as `tfstate-${project}-${account}` and the role name
# as `tf-${project}`, so the final names are `tfstate-github-<account>`
# and `tf-github`. The consuming repo's terragrunt.hcl points its state
# at this bucket under key `github/terraform.tfstate`; the bootstrap's
# own state lives at `_bootstrap/terraform.tfstate` after migration.
#
# depends_on ensures the OIDC provider exists before the role's trust
# policy references it.
module "state_backend" {
  # Pinned to the commit SHA that v0.1.0 points to, per CKV_TF_1: module
  # sources from a git URL should pin to an immutable commit, not a tag
  # name (tags can be force-pushed). The trailing comment records the
  # human-readable tag this SHA materialized from so future bumps are
  # traceable. Update both together when bumping.
  source = "git::https://github.com/dryvist/terraform-aws-template.git?ref=c85894b3667cc753a3d5ac07b50e9a7be9302331" # v0.1.0

  project        = "github"
  github_org     = var.github_org
  github_repo    = var.github_repo
  branch_pattern = var.branch_pattern
  aws_region     = var.aws_region

  operator_user_arns = var.operator_user_arns

  depends_on = [aws_iam_openid_connect_provider.github]
}
