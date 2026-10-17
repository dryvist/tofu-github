# Organization configuration

The workspace's `github_owner` selects `config/orgs/<github_owner>/`. Each
file is optional; absent files mean defaults or no opt-in. Repository metadata
otherwise comes from the selected organization's live GitHub data.

Shared policy values stay in `config/commit-message-pattern.txt` and
`config/rulesets-defaults.yml`. The `.gitkeep` files mark supported owners
that currently need no overrides.

`runner-groups.yml` is optional and enables self-hosted runner groups only for
owners that have self-hosted runners.
