# Organization configuration

Each workspace selects its organization through `github_owner`. Optional
overrides can live in `config/orgs/<github_owner>/`; a missing org directory
means shared defaults apply. Repository metadata comes from the selected
organization's live GitHub data.

Shared policy values stay in `config/commit-message-pattern.txt` and
`config/rulesets-defaults.yml`. It also enables the PR-Agent runner group for
every organization by default. `runner-groups.yml` can set
`self_hosted_runners: false` to disable the group or override its workflow list.
