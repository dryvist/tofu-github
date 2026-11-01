resource "github_organization_custom_properties" "ai_untrusted_ok" {
  property_name      = "ai-untrusted-ok"
  value_type         = "single_select"
  required           = true
  description        = "Allows lower-trust AI agents to access this repository"
  default_value      = "false"
  allowed_values     = ["true", "false"]
  values_editable_by = "org_actors"
}

# Listed repositories, plus every public repository when all_public is true,
# opt into lower-trust AI sandbox access. Private repositories never qualify.
locals {
  ai_untrusted_ok_repos = distinct(concat(
    [
      for name in data.github_repositories.org.names : name
      if contains(try(local.ai_untrusted_config.repos, []), name)
    ],
    try(data.github_repositories.public[0].names, []),
  ))
}

resource "github_repository_custom_property" "ai_untrusted_ok" {
  for_each = toset(local.ai_untrusted_ok_repos)

  repository     = each.value
  property_name  = github_organization_custom_properties.ai_untrusted_ok.property_name
  property_type  = "single_select"
  property_value = ["true"]
}
