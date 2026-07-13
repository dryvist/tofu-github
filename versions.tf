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

  # hostname and organization are intentionally omitted so no internal FQDN
  # or org login is committed to this public repo. OpenTofu reads them from
  # TF_CLOUD_HOSTNAME / TF_CLOUD_ORGANIZATION at run time.
  cloud {
    workspaces {
      name = "tofu-github"
    }
  }
}
