variable "manage_all_repos" {
  description = <<-EOT
    Invert the repo inventory from opt-in to opt-out.

    Default (false): only the repos listed in config/repos.yml are managed.
    That is how repos in this org end up born ungoverned — the org rulesets
    bind every repo automatically, but repo SETTINGS (merge methods,
    auto-merge, branch deletion, Dependabot, the public-only secret-scanning
    block, and the git-flow develop branch) reach only listed repos, and most
    of the org is not listed.

    Set to true and every unarchived org repo is enumerated at plan time and
    brought under module.repo_settings, with config/repos.yml entries acting as
    per-repo overrides. Enumerated repos inherit their live description, topics
    and visibility, so nothing is blanked.

    STAGED, NOT ENABLED. Flipping this is a large, org-wide blast radius: read
    the full plan before applying, and expect the repository imports to adopt
    every enumerated repo on the first run. Enable deliberately with
    `-var manage_all_repos=true`, never as a side effect of another change.

    `tofu plan -var manage_all_repos=true` is also useful on its own as a
    read-only drift report: everything it proposes to adopt is a repo this
    config does not currently govern.
  EOT
  type        = bool
  default     = false
}
