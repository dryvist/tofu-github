# terraform-github

Terraform-managed GitHub **organization governance** for the `dryvist` org:
rulesets, required workflows, and (over time) org/repo settings — as code, in
one place, instead of click-ops scattered across 32 repos.

## Why this exists

GitHub doesn't auto-inherit CI config across repos. The old pattern was a
reusable workflow plus a per-repo `uses:` call and a per-repo `.markdownlint*`
file in every repo — N copies that drift. Now that `dryvist` is a real org (on
the Team plan, which gained org rulesets in June 2025), governance can be
defined **once** here and applied to **every** repo automatically.

## What it manages today

| Resource | Effect |
| --- | --- |
| `github_organization_ruleset.org_push_protection` | Native GitHub push rules at the git layer (no workflow runs). Hard ceiling on individual file size + banned-extension list, applied to every repo, every ref. Thresholds + list live in `config/rulesets-defaults.yml`. |
| `github_organization_ruleset.org_branch_protection` | Quality gate on every default branch: required signatures, linear history, branch name pattern, strict Conventional Commits regex, PR thread resolution. **No bypass** — applies to everyone including org admins. |
| `github_organization_ruleset.org_review_gate` | Review gate on every default branch: 1 approving review + CODEOWNER review on PRs. **OrganizationAdmin bypass in `pull_request` mode** so admins can merge their own PRs; bots and other contributors must obtain the review. |
| `github_organization_ruleset.markdown_lint` | Requires the markdownlint workflow in the org's `.github` repo to pass on every ref of every repo. Single source of truth: the workflow + `.markdownlint-cli2.yaml` both live in `.github`. `do_not_enforce_on_create` so brand-new repos don't fail before their default branch exists. |

Imports needed on first apply (declared in `rulesets.tf` via `import`
blocks, executed automatically by `tofu apply`):

- `org_branch_protection` ← live ruleset id 15555419 (originally named "main")
- `markdown_lint` ← live ruleset id 17062292 (originally named "Required Workflows - All Branches")

After successful apply, the `import` blocks can be removed in a follow-up
PR (they're idempotent but only useful once).

Next up (separate PRs): org Actions permissions, org-level settings, org
variables, per-repo labels and LICENSE files via `for_each`.

## Layout

```text
versions.tf       # terraform + provider pins, S3 backend (partial)
providers.tf      # github provider, GITHUB_TOKEN auth
variables.tf      # all input variables (no magic numbers in .tf below)
data.tf           # live lookups: repo IDs, org metadata — never literals
locals.tf         # config/*.yml decoded into named locals for rulesets.tf
rulesets.tf       # org rulesets + import blocks for pre-Terraform state
main.tf           # multi-file entrypoint stub (resources organized by topic)
outputs.tf       # intentionally empty — see file header
config/           # YAML thresholds + lists consumed via yamldecode(file(...))
```

CODEOWNERS is deliberately NOT committed in this repo. CODEOWNERS files
for every dryvist repo (this one included) are materialized at apply time
by a `github_repository_file` resource in a follow-up PR, with the owner
identity supplied as a Terraform variable. Keeping a static
`.github/CODEOWNERS` here would bake a specific identity into the source
tree, which the no-identity-in-code rule forbids.

`config/` holds plain-data thresholds, extension lists, label sets — read
into Terraform via `yamldecode(file(...))` and exposed as locals, never
inlined as `.tf` literals. `data.tf` holds live lookups (repo IDs, org
metadata, future repo enumerations) so no specific identity values are
baked into the code. Canonical text the org doesn't author — MIT LICENSE
body, CODE_OF_CONDUCT, etc. — is fetched at apply time from a trustworthy
upstream via `data "http"`, not committed as a local template.

## Requirements

- **OpenTofu** (>= 1.10 for S3 native locking) and the
  `integrations/github` provider, pinned in `versions.tf`. Dev shell via
  direnv:

  ```bash
  git clone git@github.com:dryvist/terraform-github.git
  cd terraform-github && direnv allow   # provides tofu, terraform, terragrunt, aws-vault
  ```

- **AWS state backend bootstrapped.** The dedicated state bucket
  (`tfstate-github-<account-id>`) and scoped IAM role (`tf-github`) must
  exist. First-time setup runs once with elevated AWS admin creds —
  see [`bootstrap/README.md`](bootstrap/README.md). After bootstrap, all
  ongoing operations use the scoped role via `aws-vault`.

- **`aws-vault` profile `tf-github`** in `~/.aws/config`. Profile shape
  is documented in `bootstrap/README.md` → "Hand off to the operator".
  Verify with `aws-vault exec tf-github -- aws sts get-caller-identity`
  before running terragrunt.

- **`GITHUB_TOKEN` with `admin:org`** (the ORG_ADMIN token tier,
  `gh-claude-org-admin`) for apply. The github provider reads it from
  the environment; the default `DRYVIST` tier is read-only on org
  rulesets and will `403` on apply.

## Usage

Daily flow (after bootstrap):

```bash
aws-vault exec tf-github -- terragrunt init    # one-time per worktree
aws-vault exec tf-github -- terragrunt plan
aws-vault exec tf-github -- terragrunt apply
```

`terragrunt.hcl` resolves the state bucket name from
`get_aws_account_id()` at runtime, so no account identifier is committed.

Validation only (no backend, no credentials):

```bash
tofu init -backend=false && tofu validate
```

First-time setup (one-time, elevated AWS creds): see
[`bootstrap/README.md`](bootstrap/README.md).

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
