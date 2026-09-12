# Cost policy

**Never apply a policy or enable a feature that costs money unless the
PR body declares the cost explicitly and the operator approves it.**
GitHub's pricing model means the cost impact of one Terraform-managed
setting can vary 100x depending on repo visibility. Before adding any
new feature flag to org settings, repo settings, or required workflows,
check this matrix. Sources are dated where they're plan-dependent;
re-verify on every pricing change announcement.

## Free everywhere (any plan, public or private)

- Org and repo **rulesets** — branch protection, push protection rules
  (`max_file_size`, `file_extension_restriction`, `file_path_restriction`,
  `max_file_path_length`), required workflows, commit message pattern,
  branch name pattern, required signatures
- Classic branch protection (legacy)
- **Dependabot** version updates + security updates + dependency graph
- Org-level secrets, variables, custom repository roles
- Default workflow GITHUB_TOKEN permissions configuration
- Issue/PR templates, labels, milestones, repository templates,
  community health files inherited from `.github`

## Free on public repos, **paid** on private repos

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

## Metered (free quota then pay-per-unit on private repos)

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

## Subscription (per-seat or per-org)

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

## PR checklist

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
