terraform {
  required_version = ">= 1.10"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  # Remote state, locking, and execution live in the homelab Terrakube
  # management tier (the iac-platform stack). Plans and applies run REMOTELY
  # on its executor: the org-admin GITHUB_TOKEN is a sensitive workspace
  # variable there and never exists on dev machines or CI runners.
  #
  # The block is intentionally empty so no internal hostname, org login, or
  # workspace name is committed to this public repo. All three come from the
  # environment at run time (Doppler / sops-sourced):
  #   TF_CLOUD_HOSTNAME       the Terrakube API FQDN
  #   TF_CLOUD_ORGANIZATION   the managing org login
  #   TF_WORKSPACE            the workspace name (tofu-github)
  # Humans authenticate once per machine with `tofu login "$TF_CLOUD_HOSTNAME"`;
  # CI presents a team token via the matching TF_TOKEN_<host> variable.
  #
  # The platform is deliberately not-24/7 (control-plane doctrine) — if
  # init/plan can't reach the host, power the node on first. Use
  # `tofu init -backend=false` for validation-only runs.
  cloud {}
}
