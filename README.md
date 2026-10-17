# tofu-github

OpenTofu-managed GitHub **organization governance** for the organization
selected by each workspace. Each organization uses the same root with its own
state and per-org configuration.

## Why this exists

Organization-level rulesets, required workflows, repository settings, and
labels apply common policy across an organization's repositories. This root
defines that policy once, and each workspace selects one organization and its
own configuration.

## What it manages today

| Resource | Effect | Source |
| --- | --- | --- |
| `github_organization_ruleset.org_push_protection` | [Push protection](#push-protection) | `rulesets-push-protection.tf` |
| `github_organization_ruleset.org_branch_protection` | [Branch protection](#branch-protection) | `rulesets-branch-protection.tf` |
| `github_organization_ruleset.required_signatures` | [Required signatures](#required-signatures) | `rulesets-branch-protection.tf` |
| `github_organization_ruleset.commit_subject_branches` | [Branch commit subjects](#branch-commit-subjects) | `rulesets-branch-protection.tf` |
| `github_organization_ruleset.org_review_gate` | [Review gate](#review-gate) | `rulesets-branch-protection.tf` |
| `github_organization_ruleset.org_automerge_manual` | [Manual-repo approval](#manual-repo-approval) | `automerge.tf` |
| `github_organization_custom_properties.*` | Organization property schemas | `automerge.tf`, `docs-publisher.tf`, `gitflow.tf`, `upstream-forks.tf` |
| `github_repository_custom_property.*` | Repository property values | `automerge.tf`, `docs-publisher.tf`, `gitflow.tf`, `upstream-forks.tf` |
| `github_organization_ruleset.docs_publisher` | [Documentation publisher](#documentation-publisher) | `docs-publisher.tf` |
| `github_organization_ruleset.org_release_freeze` | [Release freeze](#release-freeze) | `release-freeze.tf` |
| `github_organization_ruleset.markdown_lint` | [Markdown lint](#markdown-lint) | `rulesets-required-workflows.tf` |
| `github_organization_ruleset.conventions` | Repo-conventions required workflow | `rulesets-required-workflows.tf` |
| `github_organization_ruleset.ai_review` | AI-review required workflow | `rulesets-required-workflows.tf` |
| `github_organization_ruleset.org_branch_write_restriction` | [Branch-write restriction](#branch-write-restriction) | `rulesets-branch-write-restriction.tf` |
| `github_organization_ruleset.org_gitflow_*` | Git-flow branch rulesets | `rulesets-gitflow.tf` |
| `github_organization_ruleset.org_upstream_fork_protection` | Upstream-fork branch ruleset | `upstream-forks.tf` |
| `github_organization_ruleset.org_merge_gate` | Required Merge Gate checks | `merge-gate.tf` |
| `github_organization_ruleset.org_copilot_review` | Explicit Copilot review targets | `copilot-review.tf` |
| `module.repo_settings` | Repository settings | `repos.tf`, `modules/repo-settings/main.tf` |
| `github_issue_label.org` | Labels read from the org's `.github` repo | `labels.tf` |
| `github_actions_variable.iac_drift_enabled` | Per-repository IaC drift opt-in variable | `iac-drift.tf` |
| `github_actions_runner_group.homelab` | Private-repository runner group | `runner-groups.tf` |
| `github_organization_webhook.hermes_pr_review` | Optional pull-request webhook, enabled when both webhook variables are set | `org-webhook.tf` |

### Push protection

Native GitHub push rules at the git layer (no workflow runs). Hard
ceiling on individual file size + banned-extension list, applied to
every repo, every ref. Thresholds + list live in
`config/rulesets-defaults.yml`.

### Branch protection

Quality gate on every default branch: required signatures, branch name
pattern, strict Conventional Commits regex, PR thread resolution. **No
bypass** — applies to everyone including org admins.

### Required signatures

Extends required signatures to every branch. Imported from the live
org ruleset without narrowing its all-branch coverage.

### Branch commit subjects

Refuses a push to any non-default branch when a commit subject is not a
Conventional Commit or a merge message. Upstream forks are excluded.

### Review gate

Review gate on every default branch: resolved review threads on PRs, with no
required approving or CODEOWNER review. Disabled by default.

### Manual-repo approval

Applies to repos with the `automerge: manual` property, and requires no
approving review. Required status checks are the only merge gate.

### Documentation publisher

Requires the org provenance workflow and the configured approval count for
projected public documentation pull requests. The release automation and
configured triage apps bypass review in `pull_request` mode.

### Release freeze

Requires the `release-freeze` status on `develop` in repos with the
`gitflow: true` property. The ruleset defaults to `evaluate` and can be set to
`active` after the shared status workflow is called from every git-flow repo.

### Branch-write restriction

Only the GitHub Apps listed in `automation_bypass_app_ids` can create or
update a branch other than `main`. Everyone else, org admins included,
can open and merge pull requests into `main` but cannot push or create
any other branch. The list is a required workspace variable with no
default.

### Markdown lint

Requires the markdownlint workflow in the org's `.github` repo to pass
on every ref of every repo. Single source of truth: the workflow +
`.markdownlint-cli2.yaml` both live in `.github`.
`do_not_enforce_on_create` so brand-new repos don't fail before their
default branch exists.

The existing org adopts its live rulesets through these `import` blocks. The
IDs live in `config/orgs/<github_owner>/ruleset-imports.yml`; other orgs omit
that optional file:

- `org_branch_protection` ← the live ruleset originally named `main`
- `markdown_lint` ← the live disabled required-workflow ruleset
- `required_signatures` ← the live all-branch signature ruleset

Org Actions variables and secrets are configured in the secret manager and
synced to GitHub; this root does not manage them (`ai-variables.tf`). CodeQL
default setup is not an active Terraform resource here; see `code_scanning.tf`.

## Layout

```text
versions.tf       # tofu + provider pins, Terrakube cloud backend
providers.tf      # github provider, token minted per run (ephemeral)
variables.tf      # all input variables (no magic numbers in .tf below)
data.tf           # live lookups: repo IDs, org metadata — never literals
locals.tf         # shared and selected per-org config decoded into named locals
rulesets-push-protection.tf     # org_push_protection
rulesets-branch-protection.tf   # org_branch_protection, required_signatures, commit_subject_branches, org_review_gate + import blocks
rulesets-required-workflows.tf  # markdown_lint, conventions + import blocks
rulesets-gitflow.tf             # org_gitflow_*
release-freeze.tf               # org_release_freeze
rulesets-branch-write-restriction.tf  # org_branch_write_restriction
main.tf           # multi-file entrypoint stub (resources organized by topic)
outputs.tf       # intentionally empty — see file header
config/           # shared policy defaults and owner-scoped config
config/orgs/      # selected by github_owner; files are optional
```

CODEOWNERS is not committed or managed in this repo. A static
`.github/CODEOWNERS` would bake a specific identity into the source tree.

`config/` holds shared ruleset defaults. Each workspace selects the organization
with `github_owner` and the token permission set with
`github_token_permission_set`; the owner also selects
`config/orgs/<github_owner>/`. Missing per-org files mean defaults or no
opt-in, and repository metadata comes from GitHub data sources.
`config/commit-message-pattern.txt` and `config/rulesets-defaults.yml` remain
shared. The org's label set is read from
`.github/labels.yml` in that org's `.github` repository by `data.tf` and
applied by `labels.tf`; label sets are not stored in `config/`. Canonical text
the org doesn't author — MIT LICENSE body, CODE_OF_CONDUCT, etc. — is fetched
at apply time from a trustworthy upstream via `data "http"`, not committed as
a local template.

`private_repo_overrides` is the protected workspace map for repo metadata that
must stay outside this public tree. Its optional `merge_gate` map carries
required-check contexts for those repositories; the repo list is derived from
each outer repo key.

## Installation

- **OpenTofu** (>= 1.11; local pin 1.12.2 in `.opentofu-version`) and the
  `integrations/github` provider, pinned in `versions.tf`. Dev shell via
  direnv:

  ```bash
  git clone git@github.com:dryvist/tofu-github.git
  cd tofu-github && direnv allow   # provides tofu, sops, linters
  ```

- **A reachable Terrakube workspace.** State, locking, and remote
  execution come from the homelab Terrakube instance; the `tofu-github`
  workspace is
  defined as code in the platform repo. The platform is deliberately
  not-24/7 — power its node on for off-hours work.

- **One-time login per machine** (no keychain, no stored passwords). The
  `TF_CLOUD_*` coordinates (`TF_CLOUD_HOSTNAME`, `TF_CLOUD_ORGANIZATION`,
  `TF_WORKSPACE`) are a fleet-wide fact owned by the platform, stored once in
  OpenBao (`secret/platform/terrakube/main`). `.envrc` pulls them at
  `direnv allow` via the platform AppRole (`BAO_ADDR` + role/secret ID from the
  operator's environment) — so nothing sensitive, not even the internal
  endpoint, is committed in this repo:

  ```bash
  tofu login "$TF_CLOUD_HOSTNAME"
  ```

  Requires membership in the org's `terrakube-admins` team.

No AWS account, no aws-vault, no local `GITHUB_TOKEN`: `providers.tf`
mints a short-lived GitHub App installation token from OpenBao on every
run, through an `ephemeral` resource, so it is never stored or written to state.

## Usage

Daily flow:

```bash
tofu init     # one-time per worktree
tofu plan     # executes remotely; output streams back
tofu apply    # remote apply, gated on plan confirmation
```

Validation only (no backend, no credentials):

```bash
tofu init -backend=false && tofu validate
```

**Rolling out a rule safely.** Org-wide enforcement can block merges everywhere
at once. For `markdown_lint_enforcement` (legacy default `evaluate`), use the
dry-run gate before enforcing:

```bash
tofu apply                                          # evaluate (legacy default)
tofu apply -var markdown_lint_enforcement=active    # enforce
```

**New rulesets default to `active`.** The `evaluate` dry-run gate above is
specific to `markdown_lint_enforcement`'s legacy default. Rulesets added going
forward — push protection, branch protection, commit format, etc. — default
their `<name>_enforcement` variable to `"active"` and are applied enabled
directly. The variable still exists so a misbehaving rule can be disabled with
`-var <name>_enforcement=disabled` without a code change.

---

> Part of a [larger ecosystem of ~40 repos](https://docs.jacobpevans.com) — see how it all fits together.
