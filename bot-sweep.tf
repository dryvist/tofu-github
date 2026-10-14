# BOT_SWEEP_LIVE gates the scheduled bot PR automerge sweep in the shared
# workflow repo.
resource "github_actions_variable" "bot_sweep_live" {
  repository    = data.github_repository.dot_github.name
  variable_name = "BOT_SWEEP_LIVE"
  value         = "true"
}

import {
  to = github_actions_variable.bot_sweep_live
  id = "${data.github_repository.dot_github.name}:BOT_SWEEP_LIVE"
}
