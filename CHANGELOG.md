# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Releases are automated via release-please from Conventional Commits.

## [1.1.1](https://github.com/dryvist/tofu-github/compare/v1.1.0...v1.1.1) (2026-07-13)


### Bug Fixes

* describe native Terrakube IaC ([#50](https://github.com/dryvist/tofu-github/issues/50)) ([48de270](https://github.com/dryvist/tofu-github/commit/48de2707cf807f136074d32ef4216d3984394648))

## [1.1.0](https://github.com/dryvist/tofu-github/compare/v1.0.0...v1.1.0) (2026-07-13)


### Features

* **rulesets:** disable linear history and configure gitflow merges ([d573dec](https://github.com/dryvist/tofu-github/commit/d573dec9f40b2221d64d8df7fb173a999a990783))

## [1.0.0](https://github.com/dryvist/tofu-github/compare/v0.2.0...v1.0.0) (2026-07-12)


### ⚠ BREAKING CHANGES

* migrate state backend to homelab Terrakube; retire AWS/terragrunt ([#23](https://github.com/dryvist/tofu-github/issues/23))

### Features

* **actions:** add org-level AI model variables ([#9](https://github.com/dryvist/tofu-github/issues/9)) ([2a381e4](https://github.com/dryvist/tofu-github/commit/2a381e41d2b8e11948c1cd6cbb2710cf9cd8fae2))
* add AI_SWEEP_REPOS org variable for review-thread sweep ([#20](https://github.com/dryvist/tofu-github/issues/20)) ([feece90](https://github.com/dryvist/tofu-github/commit/feece902ccfb4f470b37a4ed64827a3c9eb269c4))
* add review-thread-resolver caller for instant bot-thread resolution ([#21](https://github.com/dryvist/tofu-github/issues/21)) ([134cf65](https://github.com/dryvist/tofu-github/commit/134cf65b6ac2ce2f118be0e5c006fc0bd27ae309))
* **ai-callers:** IaC rollout of AI caller workflows + ai:ready labels ([#16](https://github.com/dryvist/tofu-github/issues/16)) ([eaea156](https://github.com/dryvist/tofu-github/commit/eaea1564ee3808bef145f8b06a34667ab87504ca))
* default org-review-gate enforcement to disabled ([#26](https://github.com/dryvist/tofu-github/issues/26)) ([3c98912](https://github.com/dryvist/tofu-github/commit/3c98912a22355225a419bf652a4c479479653744))
* **gitflow:** flip nix-home, nix-devenv, nix-claude-code, nix-pxe-bootstrap to git-flow ([#42](https://github.com/dryvist/tofu-github/issues/42)) ([e508c8d](https://github.com/dryvist/tofu-github/commit/e508c8d4377d250187470e3fa4fa0e5048e30d44))
* **governance:** adopt live rulesets and repo rename ([#15](https://github.com/dryvist/tofu-github/issues/15)) ([527c409](https://github.com/dryvist/tofu-github/commit/527c4093a1a5fba9b84cd1fadef3aa359ccc768d))
* **merge-gate:** require the Astro build on docs-starlight main ([#41](https://github.com/dryvist/tofu-github/issues/41)) ([211097e](https://github.com/dryvist/tofu-github/commit/211097e791b20a5857f98c95b5168049539c8a17))
* migrate state backend to homelab Terrakube; retire AWS/terragrunt ([#23](https://github.com/dryvist/tofu-github/issues/23)) ([b5323be](https://github.com/dryvist/tofu-github/commit/b5323bed172cc570a5ebb8ef470f6ce0c6bea35c))
* pilot git-flow enforcement for five repos ([#32](https://github.com/dryvist/tofu-github/issues/32)) ([04a17cd](https://github.com/dryvist/tofu-github/commit/04a17cd267fcd8cf1642ceddf98e50ed1eb23fbb))
* pull Terrakube coords from OpenBao, retire per-repo sops ([#25](https://github.com/dryvist/tofu-github/issues/25)) ([99570dc](https://github.com/dryvist/tofu-github/commit/99570dcad0635e5480bafc69bd5e4805976d015e))
* **repos:** wire an archived flag, set true for nix-ai-server ([#28](https://github.com/dryvist/tofu-github/issues/28)) ([c3bfa96](https://github.com/dryvist/tofu-github/commit/c3bfa96e18d29bc5e0f49cc1dda0fd224d5a665d))
* **rulesets:** require Merge Gate on main for every public repo ([#40](https://github.com/dryvist/tofu-github/issues/40)) ([52a5318](https://github.com/dryvist/tofu-github/commit/52a5318794a77179b62de276ec9e3d020fd99fb9))
* **security:** stage CodeQL default-setup config pending upstream provider ([ac56e02](https://github.com/dryvist/tofu-github/commit/ac56e0255b2b69b6ab70797f6c154a309c15feab))
* source Terrakube backend coords from encrypted sops env ([#24](https://github.com/dryvist/tofu-github/issues/24)) ([bd40aa1](https://github.com/dryvist/tofu-github/commit/bd40aa18239082adfd899991faf24ac708a9df00))


### Bug Fixes

* **release:** add missing release-please workflow ([8f5430e](https://github.com/dryvist/tofu-github/commit/8f5430efcbfbb0c963f2582598991b379a33e151))
* **terrakube:** add .terraformignore so .direnv doesn't break remote uploads ([#43](https://github.com/dryvist/tofu-github/issues/43)) ([c90d886](https://github.com/dryvist/tofu-github/commit/c90d88684346b5c9e428e2e479bbe1c946f97270))

## [0.2.0](https://github.com/dryvist/tofu-github/compare/v0.1.0...v0.2.0) (2026-06-01)


### Features

* **bootstrap:** dedicated AWS state backend + scoped IAM role via terraform-aws-template ([#5](https://github.com/dryvist/tofu-github/issues/5)) ([70624bf](https://github.com/dryvist/tofu-github/commit/70624bf805edccf6e20d1b0a4c1426af95ad985b))
* foundation scaffolding for org-wide config (Step 0 of 9) ([#2](https://github.com/dryvist/tofu-github/issues/2)) ([021d3ac](https://github.com/dryvist/tofu-github/commit/021d3ac31090340b186a0285d092167be372aab6))
* org governance IaC with org-wide markdown-lint ruleset ([e611f2d](https://github.com/dryvist/tofu-github/commit/e611f2dac854a2b99976893a0e393e70c9349880))
* **rulesets:** org_push_protection — native max_file_size + banned extensions ([#3](https://github.com/dryvist/tofu-github/issues/3)) ([a0d5093](https://github.com/dryvist/tofu-github/commit/a0d5093c21b8e1b107e9de6a0629fbc796845298))
* **rulesets:** reverse-engineer org branch protection + add review gate, conventional commits ([#4](https://github.com/dryvist/tofu-github/issues/4)) ([3612969](https://github.com/dryvist/tofu-github/commit/3612969271d3d74ce4b8793862daaa42a6c2eea3))

## [Unreleased]
