# AI Agents Configuration

## Repo Purpose

`dryvist` organization governance as code: GitHub org-level rulesets, required
workflows, and (over time) org/repo settings — defined once and applied to
every repo in the org via the `integrations/github` provider, instead of
click-ops scattered across the fleet.

This repo's META / quality / CI conventions are mirrored from
[terraform-proxmox](https://github.com/dryvist/terraform-proxmox), which is the
canonical source for the workspace's Terraform tooling patterns. Mirror its
tooling, not its Proxmox domain content.

## Conventions

- **dryvist-only references.** Every owner reference in this repo — provider
  `owner`, `uses:`, renovate presets, remotes, links — is `dryvist`. Do not
  introduce any personal-account owner references; this repo manages the
  `dryvist` org and must point only at it.
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

## Applying

Org ruleset changes require the **ORG_ADMIN** token tier
(`gh-claude-org-admin`) — the provider needs `admin:org`. The default `DRYVIST`
tier is read-only on org rulesets and will `403` on apply.

Roll out enforcement safely with the `evaluate` → `active` path: new org-wide
rules default to `evaluate` (dry-run, reports in Rulesets / Insights without
blocking merges). Confirm the fleet is green in Insights, then flip to `active`.

```bash
tofu apply                                          # evaluate (default)
tofu apply -var markdown_lint_enforcement=active    # enforce
```
