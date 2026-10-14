# Per-org configuration

Set `config_org` to a directory name under `config/orgs/`. The selected
directory contains the same per-org files as the current flat configuration:
`automerge.yml`, `copilot-review.yml`, `docs-publisher.yml`, `iac-drift.yml`,
`merge-gate.yml`, and `repos.yml`.

Each directory lists only that organization's repository overrides, flags,
and policy choices. Shared files `config/commit-message-pattern.txt` and
`config/rulesets-defaults.yml` remain in `config/`.
