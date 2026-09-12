# Applying

Plans and applies execute **remotely on the homelab Terrakube**
([dryvist/iac-platform](https://github.com/dryvist/iac-platform)) via the
`cloud` block in `versions.tf` — run plain `tofu plan` / `tofu apply` and the
output streams back. The org-admin `GITHUB_TOKEN` the provider needs
(`admin:org`) is a **sensitive workspace variable in Terrakube**: it never
exists on dev machines, in CI config, or in any keychain.

Authentication (zero keychain, zero stored passwords):
`tofu login "$TF_CLOUD_HOSTNAME"` once per machine (the Terrakube API FQDN
comes from the environment — see `versions.tf`; browser → GitHub via dex;
requires membership in the org's `terrakube-admins` team). Token lands in
`~/.terraform.d/credentials.tfrc.json`. The `TF_CLOUD_*` coordinates
(hostname, org, workspace) are a fleet-wide fact owned by the platform, stored
once in OpenBao (`secret/platform/terrakube/main`) and dynamically generated
by the shared `nix-devenv` helper at `direnv allow` via the platform AppRole
(`BAO_ADDR` + role/secret ID from the operator's environment) — no manual
exports, nothing sensitive committed.

**Approval gate (testing phase)**: `tofu apply` confirms interactively;
UI-triggered runs use Terrakube's native approval-step template. This gate is
the TESTING-phase contract only — the end state is **full automation**, also
native: flip the workspace to auto-apply (approval step removed from its
template) and drive autonomous runs with Terrakube's scheduler. There is
deliberately NO CI plan/apply workflow — the platform's native flows cover
both phases (ci-gate.yml still validates offline).

**Availability window**: the platform is deliberately not-24/7 (its node
powers off nightly). If `tofu` can't reach the hostname, power the node on;
never start an apply near the nightly shutdown. Operations details:
iac-platform's `docs/runbook.md`.

**New rulesets default to `active`.** Rules added going forward — push
protection, branch protection, commit format, etc. — set their
`<name>_enforcement` variable's default to `"active"` and apply enabled
directly. No dry-run gate. The variable still exists so a misbehaving rule
can be disabled with `-var <name>_enforcement=disabled` without a code
change.

**The existing `markdown_lint_enforcement` keeps its legacy `evaluate`
default** (changing it would silently flip enforcement on the next apply for
any operator who runs `tofu apply` without overrides). Enforce explicitly:

```bash
tofu apply -var markdown_lint_enforcement=active
```
