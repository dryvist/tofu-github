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
- **No magic numbers in `.tf`.** Every numeric or string value goes in
  `variables.tf` (with type + validation + description) or in
  `config/<scope>.yml` (parsed via `yamldecode(file(...))` into a local). The
  canonical example is `var.dot_github_repository_id`: a GitHub repo ID with a
  default and validation, referenced from `rulesets.tf` as
  `var.dot_github_repository_id`. Never inline a repo ID, threshold, port,
  extension list, or branch name.
- **`config/` and `templates/` hold non-`.tf` source data.** `config/*.yml`
  carries ruleset defaults (`yamldecode`); `templates/*.tmpl` carries per-repo
  file bodies (`templatefile()`) for resources like
  `github_repository_file.license` that materialize files into every repo.
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

**New rulesets default to `active`.** Rules added going forward — push
protection, branch protection, commit format, etc. — set their
`<name>_enforcement` variable's default to `"active"` and apply enabled
directly. No dry-run gate. The variable still exists so a misbehaving rule
can be disabled with `-var <name>_enforcement=disabled` without a code
change.

**The existing `markdown_lint_enforcement` keeps its legacy `evaluate`
default** (changing it would silently flip enforcement on the next apply for
any operator who runs `tofu apply` without overrides). Enforce explicitly:

```bash
tofu apply -var markdown_lint_enforcement=active
```
