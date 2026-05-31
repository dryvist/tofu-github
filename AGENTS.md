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

## State backend

State for the org-rulesets stack lives in **its own dedicated S3 bucket
and is gated by its own scoped IAM role.** Cross-stack state-bucket
sharing is not used; every Terraform stack in this account gets its own
bucket via the `terraform-aws-template` module, on the principle that
"a misapply against this repo cannot reach another stack's state and
its IAM grants don't widen as new stacks come online."

| Component | Value |
| --- | --- |
| State bucket | `tfstate-github-<account-id>` (us-east-2) |
| State key | `github/terraform.tfstate` |
| Bootstrap state key | `_bootstrap/terraform.tfstate` (same bucket) |
| Lock | S3 native (`use_lockfile = true` — no DynamoDB) |
| Encryption | AES256 / SSE-S3 (no KMS) |
| IAM role | `tf-github` — scoped to that one bucket only |

Identity flow:

1. Operator's underlying IAM user (e.g. `terraform`) sits in `~/.aws/config`
   as a `source_profile`. MFA is required on this user — the role's
   trust policy denies sessions without `aws:MultiFactorAuthPresent`.
2. `aws-vault exec tf-github -- <cmd>` calls AWS STS to assume
   `tf-github`. aws-vault prompts for MFA once per session and caches
   the STS credentials.
3. The STS credentials reach `tofu` / `terragrunt` via environment
   variables. The `aws` provider in the github provider's wire-up
   has no work — the github provider uses `GITHUB_TOKEN`, not AWS — but
   the backend's S3 access does, and it's scoped to the one bucket.

The aws-vault profile name (`tf-github`) **matches the role name** by
convention. Sibling stacks bootstrapped via `terraform-aws-template`
follow the same pattern: profile name = `tf-<project>` = role name.

Future CI uses GitHub OIDC instead of MFA AssumeRole. The role's trust
policy already accepts `repo:<github_org>/<github_repo>` on push to
the default branch and on pull_request events — no operator user
involvement. `.github/workflows/terragrunt.yml` is not in this repo
yet; when added, it uses `aws-actions/configure-aws-credentials@v4`
with `role-to-assume = arn:aws:iam::<account>:role/tf-github`.

**Never** run this stack with the elevated bootstrap credentials
(`iam-user` or any admin identity). Those are only for one-time
`bootstrap/` applies. All ongoing operations — `terragrunt init`,
`plan`, `apply` — go through `aws-vault exec tf-github`.

First-time setup walkthrough lives in
[`bootstrap/README.md`](bootstrap/README.md). Re-run only when the
template's pinned ref bumps or the role / bucket configuration
intentionally changes.

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
