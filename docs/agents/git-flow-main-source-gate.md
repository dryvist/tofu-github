# Git-flow main-source gate

For repositories whose organization custom property `gitflow` is `true`, a
pull request into `main` must come from the same repository's `develop`
branch or from a `hotfix/<name>` branch. An enterprise-level required
workflow runs `.github/workflows/main-source-gate.yml` and reports the
`Main Source Gate` check. The ruleset that attaches it is managed outside this
root. It runs in `evaluate` mode and moves to `active` after the evaluation
results are clean.

`main` accepts merge commits only, and `develop` accepts squash merges only.
A `hotfix/<name>` branch starts from `main`: its pull request targets `main`,
and a second pull request from that branch targets `develop`. Under
[Branch-write restriction](../../README.md#branch-write-restriction), only the apps listed in
`automation_bypass_app_ids` can create or update a `hotfix/<name>` branch.
