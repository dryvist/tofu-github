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

## Applying

Plans and applies execute **remotely on the homelab Terrakube**
([dryvist/iac-platform](https://github.com/dryvist/iac-platform)) via the
`cloud` block in `versions.tf` — run plain `tofu plan` / `tofu apply` and the
output streams back. The org-admin `GITHUB_TOKEN` the provider needs
(`admin:org`) is a **sensitive workspace variable in Terrakube**: it never
exists on dev machines, in CI config, or in any keychain.

Authentication (zero keychain, zero stored passwords):
`tofu login "$TF_CLOUD_HOSTNAME"` once per machine (the Terrakube API FQDN
comes from the environment — see `versions.tf`; browser → GitHub via dex;
requires membership in the org's `terrakube-admins` team). Token lands in
`~/.terraform.d/credentials.tfrc.json`. The `TF_CLOUD_*` coordinates
(hostname, org, workspace) are decrypted from the committed, encrypted
`secrets/terrakube.sops.env` and exported by `.envrc` at direnv load (fleet
age key) — no manual exports, no plaintext hostname in the repo.

**Approval gate (testing phase)**: `tofu apply` confirms interactively;
UI-triggered runs use Terrakube's native approval-step template. This gate is
the TESTING-phase contract only — the end state is **full automation**, also
native: flip the workspace to auto-apply (approval step removed from its
template) and drive autonomous runs with Terrakube's scheduler. There is
deliberately NO CI plan/apply workflow — the platform's native flows cover
both phases (ci-gate.yml still validates offline).

**Availability window**: the platform is deliberately not-24/7 (its node
powers off nightly). If `tofu` can't reach the hostname, power the node on;
never start an apply near the nightly shutdown. Operations details:
iac-platform's `docs/runbook.md`.

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

## State backend

State lives in the homelab **Terrakube** instance (TFC-compatible remote
backend; workspace `tofu-github`), which stores state objects in the
homelab object store and holds the run lock itself. Locking is inherent:
concurrent runs against the workspace queue behind the active one.

| Component | Value |
| --- | --- |
| Backend | empty `cloud {}` block; host/org/workspace from `TF_CLOUD_*` env |
| Workspace | `tofu-github` (engine: tofu, version pinned platform-side) |
| Execution | Remote, on the platform's executor |
| Provider credential | `GITHUB_TOKEN` = sensitive Terrakube workspace variable |
| Workspace definition | Code, in iac-platform `tofu/terrakube/workspaces.tf` |

There is **no AWS involvement**: the previous S3 + `tf-github` IAM design
(bootstrap/, terragrunt.hcl, aws-vault, MFA) was retired without ever being
applied — this stack's first-ever state was created in Terrakube. History:
the AWS design is preserved in git before this migration; do not resurrect
it. Fleet siblings still on S3 migrate via `tofu init` state migration,
NOT by re-bootstrapping AWS.

Import-adoption of the live org rulesets (created out-of-band before this
repo was ever applied) happens via the committed `import` blocks in
`rulesets.tf` with GitHub-assigned IDs in `config/rulesets-defaults.yml` —
the first plan must show those resources as imports / no-op updates, never
as create-or-destroy.

## Cost policy

**Never apply a policy or enable a feature that costs money unless the
PR body declares the cost explicitly and the operator approves it.**
GitHub's pricing model means the cost impact of one Terraform-managed
setting can vary 100x depending on repo visibility. Before adding any
new feature flag to org settings, repo settings, or required workflows,
check this matrix. Sources are dated where they're plan-dependent;
re-verify on every pricing change announcement.

### Free everywhere (any plan, public or private)

- Org and repo **rulesets** — branch protection, push protection rules
  (`max_file_size`, `file_extension_restriction`, `file_path_restriction`,
  `max_file_path_length`), required workflows, commit message pattern,
  branch name pattern, required signatures, linear history
- Classic branch protection (legacy)
- **Dependabot** version updates + security updates + dependency graph
- Org-level secrets, variables, custom repository roles
- Default workflow GITHUB_TOKEN permissions configuration
- Issue/PR templates, labels, milestones, repository templates,
  community health files inherited from `.github`

### Free on public repos, **paid** on private repos

These features require [GitHub Advanced Security](https://docs.github.com/en/billing/concepts/product-billing/github-advanced-security)
(GHAS) on private repos. GHAS on Team plan is a per-active-committer
monthly add-on, billed at **$30/committer/month for Code Security** and
**$19/committer/month for Secret Protection** as of 2026-05. An "active
committer" is anyone whose commit landed on a GHAS-enabled repo in the
last 90 days.

| Setting | Free on public | Paid on private |
| --- | --- | --- |
| `secret_scanning_enabled_for_new_repositories` | yes | yes — Secret Protection |
| `secret_scanning_push_protection_enabled_for_new_repositories` | yes | yes — Secret Protection |
| Code scanning (CodeQL default setup, custom queries) | yes | yes — Code Security |
| Security overview, risk metrics | yes | yes — Code Security |
| `secret_scanning_validity_checks_enabled` | yes | yes — Secret Protection |

**Policy**: enable these org defaults only when every current and future
repo will be public. The dryvist org has both visibilities, so org
defaults stay off for the GHAS-gated settings; per-repo opt-in is
allowed for repos where the cost has been approved.

### Metered (free quota then pay-per-unit on private repos)

GitHub Actions usage on private repos has a free quota then meters by
the minute. Public repos are always free for both GitHub-hosted and
self-hosted runners. Recent change: as of **2026-03-01**, self-hosted
runners on private repos incur a `$0.002/min` GitHub Actions platform
fee — previously zero. See
[Pricing changes for GitHub Actions (2026)](https://resources.github.com/actions/2026-pricing-changes-for-github-actions/).

| Resource | Free tier (Team plan) | Beyond free (2026-01 pricing) |
| --- | --- | --- |
| Actions minutes, Linux GitHub-hosted, private | 3000 min/month | metered, see GitHub Actions pricing |
| Actions minutes, macOS GitHub-hosted, private | (counts 10x against quota) | $0.048/min |
| Actions minutes, Windows GitHub-hosted, private | (counts 2x against quota) | metered |
| Actions minutes, self-hosted, private | n/a | $0.002/min platform fee (2026-03-01+) |
| Actions storage (artifacts, logs) | 2 GB | $0.25/GB-month |
| Packages storage | 2 GB | $0.25/GB-month |
| Public repos (any runner type) | unlimited | $0.00 |

**Policy**: do not add a Terraform resource that allocates Actions or
Packages capacity on private repos without first declaring the expected
monthly cost and an approved ceiling in the PR body. For private-repo
CI, prefer self-hosted runners (the per-minute compute is yours, only
the $0.002/min platform fee accrues) over GitHub-hosted runners.

### Subscription (per-seat or per-org)

| Product | Cost |
| --- | --- |
| Copilot Business (org) | per-seat monthly |
| Copilot Enterprise | higher per-seat tier |
| Codespaces | per-hour compute + storage when running |
| GHAS Code Security | $30/committer/month (private repos only) |
| GHAS Secret Protection | $19/committer/month (private repos only) |
| Larger / GPU-enabled GitHub-hosted runners | rate per runner size, billed by the minute |

These are not configured by Terraform here. The mention is so a PR
proposing a `github_*` resource that auto-allocates any of these gets
caught.

### PR checklist

Every PR that adds or modifies any of:

- A `github_organization_settings` attribute
- A `github_actions_organization_*` resource
- A `github_repository` setting that affects visibility, GHAS, or
  Actions on private repos
- A required workflow that runs on private repos
- A `github_codespaces_*` or `github_copilot_*` resource

must include a "**Cost impact**" line in the PR body. State `free`
with the reason (e.g. "applies only to public repos", "native ruleset,
zero per-seat cost") or state the per-unit rate and the expected
monthly burn. PRs lacking this line are not ready to merge.
