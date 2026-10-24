resource "github_organization_custom_properties" "ai_untrusted_ok" {
  property_name      = "ai-untrusted-ok"
  value_type         = "single_select"
  required           = true
  description        = "Allows lower-trust AI agents to access this repository"
  default_value      = "false"
  allowed_values     = ["true", "false"]
  values_editable_by = "org_actors"
}
