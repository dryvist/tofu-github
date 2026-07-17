config {
  format     = "compact"
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
  version = "0.15.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"

  # TEMPORARY (2026-07-17): pinned to PGP because the default "auto" mode
  # crashes. GitHub removed the `bundle` field from attestation API responses,
  # so tflint >=0.61 nil-derefs while verifying this plugin and never reaches
  # the lint stage. Upstream fix: terraform-linters/tflint#2593 (unreleased).
  # "pgp" still verifies the plugin cryptographically via the legacy signing
  # key -- it is NOT "none", which would skip verification entirely.
  # REVERT to the default (delete this line) once #2593 ships.
  signature = "pgp"
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}
