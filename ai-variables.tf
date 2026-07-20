# Org Actions variables and secrets are NOT managed here — they are configured
# in the secret manager and synced to GitHub. The executor's credential has no
# Actions variable/secret write, so any such resource 403s on every apply.
#
# Do not reintroduce github_actions_organization_variable / _secret.
#
# `destroy = false` forgets the resources without deleting the live variables.
# One-shot: deletable after a clean apply.

removed {
  from = github_actions_organization_variable.ai_sweep_repos

  lifecycle {
    destroy = false
  }
}

removed {
  from = github_actions_organization_variable.ai_models

  lifecycle {
    destroy = false
  }
}
