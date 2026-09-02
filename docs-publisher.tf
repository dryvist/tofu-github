resource "github_organization_ruleset" "docs_publisher" {
  name        = "docs-publisher"
  target      = "branch"
  enforcement = var.docs_publisher_enforcement

  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
    repository_name {
      include = [local.docs_publisher.repository]
      exclude = []
    }
  }

  rules {
    required_workflows {
      do_not_enforce_on_create = true

      required_workflow {
        repository_id = data.github_repository.dot_github.repo_id
        path          = local.docs_publisher.required_workflow.path
        ref           = local.docs_publisher.required_workflow.ref
      }
    }

    pull_request {
      required_approving_review_count   = local.docs_publisher.pull_request.required_approvals
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = true
      required_review_thread_resolution = true
      allowed_merge_methods             = local.docs_publisher.pull_request.allowed_merge_methods
    }
  }
}
