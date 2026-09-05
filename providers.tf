provider "vault" {
  # Injected workload-identity token lacks auth/token/create; do not derive a child token.
  skip_child_token = true
}

# Mint an installation token for this run rather than reading a stored one.
#
# This previously read a static GITHUB_TOKEN out of KV. A stored token expires,
# and when it did every plan failed with `401 Bad credentials` against the org
# lookup — a failure mode an engine-minted token does not have. The token is
# never written to state: `ephemeral` resources exist for exactly this, and
# `vault_kv_secret_v2` could not be used because minting is a write with a body,
# not a read.
#
# `write_fields` selects from the response, so only the token itself is
# extracted. The permission set is installation-scoped on the OpenBao side, so
# no installation_id is passed here.
ephemeral "vault_generic_endpoint" "github_token" {
  path         = "github/token/dryvist-full-automation"
  data_json    = jsonencode({})
  write_fields = ["token"]
}

provider "github" {
  owner = "dryvist"
  token = ephemeral.vault_generic_endpoint.github_token.write_data["token"]
}
