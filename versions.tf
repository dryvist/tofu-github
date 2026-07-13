terraform {
  required_version = ">= 1.11"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.10"
    }
  }

  cloud {
    hostname     = "terrakube-api.jacobpevans.com"
    organization = "dryvist"

    workspaces {
      name = "tofu-github"
    }
  }
}
