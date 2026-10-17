output "full_name" {
  description = "owner/name of the managed repo, from the provider-resolved live value."
  value       = github_repository.this.full_name
}

output "repo_id" {
  description = "Provider-assigned numeric id of the managed repo."
  value       = github_repository.this.repo_id
}

output "node_id" {
  description = "Provider-assigned GraphQL node id of the managed repo."
  value       = github_repository.this.node_id
}
