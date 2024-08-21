# The following locals are used to extract the Policy Definition
# configuration from the archetype module outputs.
locals {
  es_policy_exemptions_by_management_group = flatten([
    for archetype in values(module.management_group_archetypes) :
    archetype.configuration.azurerm_policy_exemption
  ])
  es_policy_exemptions_by_subscription = local.empty_list
  es_policy_exemptions = concat(
    local.es_policy_exemptions_by_management_group,
    local.es_policy_exemptions_by_subscription,
  )
}

# The following locals are used to build the map of Policy
# Definitions to deploy.
locals {
  azurerm_policy_exemptions_enterprise_scale = {
    for definition in local.es_policy_exemptions :
    definition.resource_id => definition
  }
}
