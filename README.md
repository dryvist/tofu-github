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
| `github_organization_ruleset.markdown_lint` | Requires the markdownlint workflow in `dryvist/.github` to pass on the default branch of **every** repo in the org. Single source of truth: the workflow + `.markdownlint-cli2.yaml` both live in `dryvist/.github`. |

Start small — this is the seed. Branch protection, the verified-signature
policy, file-size limits, and repo settings can move here next.

## Layout

```text
versions.tf    # terraform + provider pins, S3 backend (partial)
providers.tf   # github provider (owner = dryvist), GITHUB_TOKEN auth
variables.tf   # markdown_lint_enforcement (evaluate | active | disabled)
rulesets.tf    # org rulesets
```

## Installation

Clone and enter the dev shell (direnv auto-loads OpenTofu via the org's Nix
flake):

```bash
git clone git@github.com:dryvist/terraform-github.git
cd terraform-github
direnv allow   # provides tofu, terraform, terragrunt
```

**Auth and tier:** the provider reads `GITHUB_TOKEN`. Managing org rulesets
requires `admin:org` — the **ORG_ADMIN** token tier (`gh-claude-org-admin`).
The default `DRYVIST` tier is read-only on org rulesets and will `403` on apply.

## Usage

State lives in S3 (org convention). Backend values (bucket / key / region) are
supplied at init — never committed, because the bucket name embeds the AWS
account ID:

```bash
tofu init -backend-config=bucket=<state-bucket> \
          -backend-config=key=terraform-github/terraform.tfstate \
          -backend-config=region=us-east-2
```

Validation needs no backend or credentials:

```bash
tofu init -backend=false && tofu validate
```

**Rolling out a rule safely.** Org-wide enforcement can block merges everywhere
at once. Default the enforcement to `evaluate` (dry-run — reports in
**Rulesets / Insights** without blocking), confirm the fleet is green, then flip
to `active`:

```bash
tofu apply                                          # evaluate (default)
tofu apply -var markdown_lint_enforcement=active    # enforce
```
