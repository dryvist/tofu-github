output "state_bucket" {
  description = "S3 bucket the consuming repo writes its state to."
  value       = module.state_backend.state_bucket
}

output "state_bucket_arn" {
  description = "ARN of the state bucket."
  value       = module.state_backend.state_bucket_arn
}

output "tf_role_arn" {
  description = "IAM role ARN the operator assumes (via aws-vault + MFA) and CI assumes (via GitHub OIDC) to run terraform-github."
  value       = module.state_backend.tf_role_arn
}

output "aws_region" {
  description = "Region where the state bucket lives."
  value       = module.state_backend.aws_region
}

output "state_key_prefix" {
  description = "Prefix the consuming repo writes its state objects under."
  value       = module.state_backend.state_key_prefix
}

output "backend_config" {
  description = "Ready-to-paste `terraform { backend \"s3\" {} }` block for the consuming repo's backend configuration. Use this to fill the commented-out backend block in `versions.tf` before running `tofu init -migrate-state`."
  value       = module.state_backend.backend_config
}
