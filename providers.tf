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
# extracted. OpenBao selects the installation by org name and applies the
# installation's permissions, so no installation_id is passed here.
ephemeral "vault_generic_endpoint" "github_token" {
  path         = "github-admin/token"
  data_json    = jsonencode({ org_name = var.github_owner })
  write_fields = ["token"]
}

provider "github" {
  owner = var.github_owner
  token = ephemeral.vault_generic_endpoint.github_token.write_data["token"]
}

provider "restapi" {
  uri                  = "https://api.github.com"
  write_returns_object = true

  headers = {
    Authorization          = "Bearer ${ephemeral.vault_generic_endpoint.github_token.write_data["token"]}"
    Accept                 = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
  }
}
