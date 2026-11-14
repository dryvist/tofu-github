mock_provider "github" {
  mock_resource "github_repository" {
    defaults = {
      repo_id = 1
    }
  }
}

run "private_to_public_flip_leaves_scanning_unset" {
  command = plan

  variables {
    name            = "sample"
    description     = "Sample repository"
    visibility      = "public"
    live_visibility = "private"
  }

  assert {
    condition     = length(github_repository.this.security_and_analysis) == 0
    error_message = "A repo still private on GitHub must not get a security_and_analysis block."
  }
}

run "live_public_repo_gets_scanning" {
  command = plan

  variables {
    name            = "sample"
    description     = "Sample repository"
    visibility      = "public"
    live_visibility = "public"
  }

  assert {
    condition     = github_repository.this.security_and_analysis[0].secret_scanning[0].status == "enabled"
    error_message = "A repo public on GitHub must have secret scanning enabled."
  }
}
