# Conventions

- **No personal-account references.** Any owner reference that must exist —
  provider configuration, `uses:`, Renovate presets, remotes, and links —
  points at the org selected by the workspace, never at a personal account.
- **No magic numbers in `.tf`. No specific identities in `.tf` either.**
  Numeric or string values land in `variables.tf` (with type + validation +
  description) or in shared `config/` files and the selected
  `config/orgs/<github_owner>/` files (parsed via `yamldecode(file(...))` into a
  local). For identifiers that GitHub already knows about — repo IDs and
  account IDs — use a `data` source in `data.tf` and reference the live value
  at apply time. The canonical example is
  `data.github_actions_organization_variables.org`: it reads the release App
  ID from the org instead of writing it down.
- **Organization selection is workspace-scoped.** `var.github_owner` selects
  the provider owner and the optional `config/orgs/<github_owner>/` directory.
  A missing directory or file means defaults or no opt-in. The ruleset
  defaults and commit-message pattern remain shared.
- **Keep org logins out of shared policy values.** Per-org config files may
  name repositories and their policy choices. Use `var.github_owner` or the
  provider-resolved `local.org` for organization logins wherever Terraform
  expressions allow it. Do not hardcode an org login in resource expressions;
  comments or documentation in a config file may describe an org-specific
  workflow path when that text is not an evaluated Terraform value.
- **`config/` holds non-`.tf` source data.** YAML thresholds, lists, and
  any structured input the rulesets read at apply time. Canonical text the
  org doesn't author (MIT LICENSE body, CODE_OF_CONDUCT, etc.) is fetched
  from a trustworthy upstream via `data "http"` — never committed as a
  local template.
- **Keep other account identities explicit.** Repository IDs and other
  GitHub-assigned identifiers use data sources where GitHub exposes them.
  Account identities that must materialize at apply time, such as CODEOWNERS
  entries, come from an operator-supplied Terraform variable, not a hardcoded
  value. The same root must work for each workspace-selected org.
- **No local markdownlint config.** Enterprise rulesets own required-workflow
  policy. Keep markdownlint's workflow and `.markdownlint-cli2.yaml` in the
  org's `.github` repo; never add a local `.markdownlint*` file here.
- **`terraform_docs` is intentionally omitted** from `.pre-commit-config.yaml`:
  it injects HTML-anchored tables into the README that trip the org markdownlint
  ruleset (MD033).
- Conventional commits: `type(scope): description`.
- All commits must be GPG-signed (signing key varies per machine; see local
  `git config user.signingkey`).
- Never commit secrets — store references, not values. Backend bucket/key and
  the `GITHUB_TOKEN` are supplied at runtime, never hardcoded.
