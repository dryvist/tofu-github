provider "vault" {
  # Injected workload-identity token lacks auth/token/create; do not derive a child token.
  skip_child_token = true
}

ephemeral "vault_kv_secret_v2" "github" {
  mount = "secret"
  name  = "infrastructure/github"
}

provider "github" {
  owner = "dryvist"
  token = ephemeral.vault_kv_secret_v2.github.data.GITHUB_TOKEN
}
