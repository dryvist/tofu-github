terraform {
  required_version = ">= 1.11"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.10"
    }
  }

  # Remote state, locking, and execution live in the homelab Terrakube
  # management tier (the iac-platform stack). Plans and applies run REMOTELY
  # on its executor: the org-admin GITHUB_TOKEN is a sensitive workspace
  # variable there and never exists on dev machines or CI runners.
  #
  # The block is intentionally empty so no internal hostname, org login, or
  # workspace name is committed to this public repo. All three come from the
  # environment at run time (pulled dynamically via the nix-devenv tofu helper):
  #   TF_CLOUD_HOSTNAME       the Terrakube API FQDN
  #   TF_CLOUD_ORGANIZATION   the managing org login
  #   TF_WORKSPACE            the workspace name (dynamically extracted)
  # Operators authenticate once per machine with `tofu login "$TF_CLOUD_HOSTNAME"`
  # (Terrakube's native flow; no team token — consumers use the platform's own
  # run flows, not a stored CI credential).
  #
  # The platform is deliberately not-24/7 (control-plane doctrine) — if
  # init/plan can't reach the host, power the node on first. Use
  # `tofu init -backend=false` for validation-only runs.
  cloud {
    workspaces {
    }
  }
}
