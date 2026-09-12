# Conventions

- **No personal-account references.** Any owner reference that must exist —
  `providers.tf` `owner`, `uses:`, renovate presets, remotes, links — points
  at the org this repo manages, never at a personal account. (See also the
  org-agnostic-code rule below: the org login appears in `providers.tf` and
  documentation strings only, never in `.tf` resource bodies or variable
  descriptions.)
- **No magic numbers in `.tf`. No specific identities in `.tf` either.**
  Numeric or string values land in `variables.tf` (with type + validation +
  description) or `config/<scope>.yml` (parsed via `yamldecode(file(...))`
  into a local). For identifiers that GitHub already knows about — repo IDs,
  the org's own login, account IDs — use a `data` source in `data.tf` and
  reference the live value at apply time, never a literal default. The
  canonical example is `data.github_repository.dot_github`: looks up the
  org's `.github` repo by name (org is implied by the provider's `owner`),
  exposes its numeric `repo_id` to org rulesets.
- **Code stays org-agnostic.** Don't bake the org's name into variable
  descriptions, comments, or documentation strings. Write by role: "the
  org's `.github` repo", "the org owner declared in the provider". The
  `providers.tf` `owner = "dryvist"` is the single allowed mention of the
  org login; everything else references roles.
- **`config/` holds non-`.tf` source data.** YAML thresholds, lists, and
  any structured input the rulesets read at apply time. Canonical text the
  org doesn't author (MIT LICENSE body, CODE_OF_CONDUCT, etc.) is fetched
  from a trustworthy upstream via `data "http"` — never committed as a
  local template.
- **No identities anywhere except `providers.tf` owner.** No usernames,
  account logins, email addresses, or person-tied identifiers in `.tf`
  resource bodies, comments, variable descriptions, `config/*.yml`, or
  `.github/CODEOWNERS`-style files committed in this repo. Identities
  that need to materialize at apply time (e.g. CODEOWNERS for managed
  repos) come from a Terraform variable that the operator supplies via
  `-var` or `TF_VAR_`, never a default. The repo must clone cleanly into
  another org without a single rename.
- **No local markdownlint config.** This repo *defines* the org-wide
  markdownlint ruleset (`github_organization_ruleset.markdown_lint`), whose
  single source of truth is the workflow + `.markdownlint-cli2.yaml` in
  `dryvist/.github`. Adding a local `.markdownlint*` file here would create the
  exact per-repo drift this repo exists to eliminate — never add one.
- **`terraform_docs` is intentionally omitted** from `.pre-commit-config.yaml`:
  it injects HTML-anchored tables into the README that trip the org markdownlint
  ruleset this repo itself defines (MD033).
- Conventional commits: `type(scope): description`.
- All commits must be GPG-signed (signing key varies per machine; see local
  `git config user.signingkey`).
- Never commit secrets — store references, not values. Backend bucket/key and
  the `GITHUB_TOKEN` are supplied at runtime, never hardcoded.
