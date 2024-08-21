resource "azapi_resource" "policy_exemption" {
  for_each = local.azurerm_policy_exemptions_enterprise_scale

  type = "Microsoft.Authorization/policyExemptions@${try(each.value.template.apiVersion, "2022-07-01-preview")}"
  name = each.value.template.name
  parent_id = try(each.value.template.scope, each.value.template.scope_id)
  schema_validation_enabled = try(each.value.template.schemaValidationEnabled, true)
  body = jsonencode({
    properties = each.value.template.properties
  })
  depends_on = [
    time_sleep.after_azurerm_management_group,
  ]
}

resource "time_sleep" "after_azurerm_policy_exemption" {
  depends_on = [
    time_sleep.after_azurerm_management_group,
    azapi_resource.policy_exemption,
  ]

  triggers = {
    "azapi_resource_policy_exemption" = jsonencode(keys(azapi_resource.policy_exemption))
  }

  create_duration  = local.create_duration_delay["after_azurerm_policy_exemption"]
  destroy_duration = local.destroy_duration_delay["after_azurerm_policy_exemption"]
}