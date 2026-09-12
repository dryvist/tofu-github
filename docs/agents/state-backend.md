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
| Provider credential | `GITHUB_TOKEN` = sensitive Terrakube workspace variable |
| Workspace definition | Code, in iac-platform `tofu/terrakube/workspaces.tf` |

There is **no AWS involvement**: the previous S3 + `tf-github` IAM design
(the bootstrap directory, generated backend wrapper, aws-vault, and MFA path) was retired without ever being
applied — this stack's first-ever state was created in Terrakube. History:
the AWS design is preserved in git before this migration; do not resurrect
it. Fleet siblings still on S3 migrate via `tofu init` state migration,
NOT by re-bootstrapping AWS.

Import-adoption of the live org rulesets (created out-of-band before this
repo was ever applied) happens via the committed `import` blocks in
`rulesets.tf` with GitHub-assigned IDs in `config/rulesets-defaults.yml` —
the first plan must show those resources as imports / no-op updates, never
as create-or-destroy.

