mock_provider "github" {
  mock_resource "github_repository" {
    defaults = {
      repo_id = 1
    }
  }
}

run "without_fork_of_leaves_fork_arguments_unset" {
  command = plan

  # Unset arguments are computed; pin their computed values so the assertion
  # proves the configuration did not set them.
  override_resource {
    target = github_repository.this
    values = {
      fork         = "false"
      source_owner = ""
      source_repo  = ""
    }
  }

  variables {
    name        = "ordinary-repo"
    description = "Ordinary repository"
    visibility  = "public"
  }

  assert {
    condition = (
      github_repository.this.fork == "false" &&
      github_repository.this.source_owner == "" &&
      github_repository.this.source_repo == ""
    )
    error_message = "An unset fork_of must leave all native fork arguments unset."
  }
}

run "fork_of_sets_native_fork_arguments" {
  command = plan

  variables {
    name        = "sample-fork"
    description = "Forked repository"
    visibility  = "public"
    fork_of     = "upstream-owner/upstream-repo"
  }

  assert {
    condition = (
      github_repository.this.fork == "true" &&
      github_repository.this.source_owner == "upstream-owner" &&
      github_repository.this.source_repo == "upstream-repo"
    )
    error_message = "fork_of must set fork=true and split the upstream owner and repository."
  }
}

run "fork_of_requires_owner_and_repository" {
  command = plan

  variables {
    name        = "invalid-fork"
    description = "Invalid fork source"
    visibility  = "public"
    fork_of     = "missing-slash"
  }

  expect_failures = [var.fork_of]
}
