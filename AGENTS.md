---
skill-groups: [core, git, homelab]
---
# AI Agents Configuration

`dryvist` organization governance as code: GitHub org-level rulesets, required
workflows, and (over time) org/repo settings — defined once and applied to
every repo in the org via the `integrations/github` provider, instead of
click-ops scattered across the fleet.

This repo's META / quality / CI conventions are mirrored from
[terraform-proxmox](https://github.com/dryvist/terraform-proxmox), which is the
canonical source for the workspace's Terraform tooling patterns. Mirror its
tooling, not its Proxmox domain content.

Full docs live under `docs/agents/`, one topic per page:

- [Registering a repo](docs/agents/registering-a-repo.md) — the
  `config/repos.yml` opt-in model, what an unlisted repo gets vs. loses, and
  the two gotchas when adding an entry.
- [Conventions](docs/agents/conventions.md) — no personal-account references,
  no magic numbers or identities in `.tf`, org-agnostic code, `config/`
  usage, commit and signing rules.
- [Applying](docs/agents/applying.md) — plans and applies run remotely on the
  homelab Terrakube, authentication, the approval-gate testing phase, and
  new-ruleset enforcement defaults.
- [State backend](docs/agents/state-backend.md) — the Terrakube-hosted remote
  backend, workspace details, and import-adoption of pre-existing live
  rulesets.
- [Cost policy](docs/agents/cost-policy.md) — what's free vs. paid across
  plans, GHAS pricing, metered Actions/Packages usage, subscription
  products, and the required PR cost-impact checklist.
