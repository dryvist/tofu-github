# Registering a repo

Every unarchived org repo is governed: `repos.tf` enumerates the org at plan
time and brings each repo under `module.repo_settings` (merge methods,
auto-merge, branch deletion, Dependabot, the public-only secret-scanning
block). An unlisted repo inherits its live description, topics and visibility,
and is git-flow when its default branch is `develop`. A new repo is adopted on
the next apply.

`config/repos.yml` holds per-repo overrides only. List a repo to override the
enumerated values (an entry replaces them wholesale), to set `gitflow` or
`upstream_fork`, to keep an archived repo managed, or to create a repo that
does not exist yet.

The full creation-to-registration path lives in the org `.github` repo's
`AGENTS.md` under **New repo checklist** — that is the canonical standard and
the file agents already read. It is enforced from two sides: a PR-time
required-workflow check, and a weekly `repo-conventions-sweep` that also reports
repos missing from `config/repos.yml`. Recorded opt-outs live in the
`conventions_exempt:` key of that same file, per check rather than per repo.

Gotchas when adding an entry here:

- Look the visibility up live (`gh repo view <repo> --json visibility`). The
  secret-scanning block is cost-gated on it — see the cost policy below.
- `gitflow: true` on a repo whose default branch is not yet `develop` but that
  already has a `develop` branch needs a one-shot `import` block; `gitflow.tf`
  imports `develop` automatically only when it is already the default branch.
  The `gitflow` custom property needs no import — its create is an upsert.
