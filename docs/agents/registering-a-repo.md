# Registering a repo

`config/repos.yml` is opt-in: a repo it does not list gets org rulesets (those
bind every repo by name or custom property) but **no managed repo settings** —
no merge-method policy, no auto-merge, no branch deletion, no Dependabot, no
secret-scanning block, and on a git-flow repo no `develop` branch or default
switch. Most of the org is not listed, so most of the org is in that state.

The full creation-to-registration path lives in the org `.github` repo's
`AGENTS.md` under **New repo checklist** — that is the canonical standard and
the file agents already read. It is enforced from two sides: a PR-time
required-workflow check, and a weekly `repo-conventions-sweep` that also reports
repos missing from `config/repos.yml`. Recorded opt-outs live in the
`conventions_exempt:` key of that same file, per check rather than per repo.

Two gotchas when adding an entry here:

- Look the visibility up live (`gh repo view <repo> --json visibility`). The
  secret-scanning block is cost-gated on it — see the cost policy below.
- A repo that already ran git-flow out of band arrives with `develop` present.
  `github_branch` only creates, so it needs a one-shot `import` block; see
  `gitflow.tf`. The `gitflow` custom property needs no import — its create is
  an upsert.

`var.manage_all_repos` stages the inverse model (manage every unarchived org
repo, with this file as overrides). It is **off**; see its docstring before
flipping it.

