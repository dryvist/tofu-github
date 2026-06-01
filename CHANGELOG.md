# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Releases are automated via release-please from Conventional Commits.

## [0.2.0](https://github.com/dryvist/terraform-github/compare/v0.1.0...v0.2.0) (2026-06-01)


### Features

* **bootstrap:** dedicated AWS state backend + scoped IAM role via terraform-aws-template ([#5](https://github.com/dryvist/terraform-github/issues/5)) ([70624bf](https://github.com/dryvist/terraform-github/commit/70624bf805edccf6e20d1b0a4c1426af95ad985b))
* foundation scaffolding for org-wide config (Step 0 of 9) ([#2](https://github.com/dryvist/terraform-github/issues/2)) ([021d3ac](https://github.com/dryvist/terraform-github/commit/021d3ac31090340b186a0285d092167be372aab6))
* org governance IaC with org-wide markdown-lint ruleset ([e611f2d](https://github.com/dryvist/terraform-github/commit/e611f2dac854a2b99976893a0e393e70c9349880))
* **rulesets:** org_push_protection — native max_file_size + banned extensions ([#3](https://github.com/dryvist/terraform-github/issues/3)) ([a0d5093](https://github.com/dryvist/terraform-github/commit/a0d5093c21b8e1b107e9de6a0629fbc796845298))
* **rulesets:** reverse-engineer org branch protection + add review gate, conventional commits ([#4](https://github.com/dryvist/terraform-github/issues/4)) ([3612969](https://github.com/dryvist/terraform-github/commit/3612969271d3d74ce4b8793862daaa42a6c2eea3))

## [Unreleased]
