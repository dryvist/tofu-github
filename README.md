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

## Requirements

- **OpenTofu** (>= 1.6) and the `integrations/github` provider, pinned in
  `versions.tf`. The dev shell supplies the toolchain via direnv:

  ```bash
  git clone git@github.com:dryvist/terraform-github.git
  cd terraform-github && direnv allow   # provides tofu, terraform, terragrunt
  ```

- **`GITHUB_TOKEN` with `admin:org`** (the ORG_ADMIN token tier,
  `gh-claude-org-admin`) to create or modify org rulesets. The provider reads it
  from the environment.
- **S3 state backend** access — bucket / key / region supplied at init (see Usage).

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
