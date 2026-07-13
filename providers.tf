provider "vault" {}

ephemeral "vault_kv_secret_v2" "github" {
  mount = "secret"
  name  = "infrastructure/github"
}

provider "github" {
  owner = "dryvist"
  token = ephemeral.vault_kv_secret_v2.github.data.GITHUB_TOKEN
}
