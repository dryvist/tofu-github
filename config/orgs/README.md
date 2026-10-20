# Organization configuration

Each workspace selects its organization through `github_owner`. Optional
overrides can live in `config/orgs/<github_owner>/`; a missing org directory
means shared defaults apply. Repository metadata comes from the selected
organization's live GitHub data.

Shared policy values stay in `config/commit-message-pattern.txt` and
`config/rulesets-defaults.yml`.
