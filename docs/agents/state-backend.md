# State backend

State lives in the homelab **Terrakube** instance (TFC-compatible remote
backend; workspace `tofu-github`), which stores state objects in the
homelab object store and holds the run lock itself. Locking is inherent:
concurrent runs against the workspace queue behind the active one.

| Component | Value |
| --- | --- |
| Backend | empty `cloud {}` block; host/org/workspace from `TF_CLOUD_*` env |
| Workspace | `tofu-github` (engine: tofu, version pinned platform-side) |
| Execution | Remote, on the platform's executor |
| Provider credential | Installation token minted per run from OpenBao (`ephemeral` in `providers.tf`); never in state |
| Workspace definition | Code, in iac-platform `tofu/terrakube/workspaces.tf` |

There is **no AWS involvement**: the previous S3 + `tf-github` IAM design
(the bootstrap directory, generated backend wrapper, aws-vault, and MFA path) was retired without ever being
applied — this stack's first-ever state was created in Terrakube. History:
the AWS design is preserved in git before this migration; do not resurrect
it. Fleet siblings still on S3 migrate via `tofu init` state migration,
NOT by re-bootstrapping AWS.

The existing org adopts its live rulesets through import blocks in
`rulesets-branch-protection.tf` (`org_branch_protection` and
`required_signatures`) and `rulesets-required-workflows.tf` (`markdown_lint`),
using GitHub-assigned IDs in its `config/orgs/<github_owner>/ruleset-imports.yml`.
Other org directories omit that optional file, so those imports are skipped.
The existing org's first plan must show imports or no-op updates, never
create-or-destroy actions for those rulesets.
