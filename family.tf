# Optional repository family classification.
locals {
  family_values = [
    "nix",
    "homelab",
    "cloud",
    "ai",
    "cribl",
    "cribl-community",
    "docs",
    "mlx",
    "governance",
    "profile",
    "visicore",
    "misc",
  ]

  # Only repos that opt in through their selected repos.yml entry receive an
  # explicit value. All other repos keep the optional property unset.
  family_repo_values = {
    for name, cfg in local.managed_repos : name => cfg.family
    if try(cfg.family, null) != null && !try(cfg.archived, false)
  }
}

resource "github_organization_custom_properties" "family" {
  property_name = "family"
  value_type    = "single_select"
  required      = false
  # Keep the default unset so repos remain unclassified until configured.
  default_value      = null
  allowed_values     = local.family_values
  values_editable_by = "org_actors"
}

resource "github_repository_custom_property" "family" {
  for_each = local.family_repo_values

  repository     = each.key
  property_name  = github_organization_custom_properties.family.property_name
  property_type  = "single_select"
  property_value = [each.value]

  # A repos.yml entry may create the repository in the same apply.
  depends_on = [module.repo_settings]
}
