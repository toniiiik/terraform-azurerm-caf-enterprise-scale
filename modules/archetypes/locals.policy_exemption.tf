# Generate the Policy Assignment configurations for the specified archetype.
# Logic implemented to determine whether Policy Assignments
# need to be loaded to save on compute and memory resources
# when none defined in archetype definition.
locals {
  archetype_policy_exemptions_list      = local.archetype_definition.policy_exemptions
  archetype_policy_exemptions_specified = try(length(local.archetype_policy_exemptions_list) > 0, false)
}

# If Policy Assignments are specified in the archetype definition, generate a list of all Policy Assignment files from the built-in and custom library locations
locals {
  custom_policy_exemptions_from_json  = local.archetype_policy_exemptions_specified && local.custom_library_path_specified ? tolist(fileset(local.custom_library_path, "**/policy_exemption_*.{json,json.tftpl}")) : null
  custom_policy_exemptions_from_yaml  = local.archetype_policy_exemptions_specified && local.custom_library_path_specified ? tolist(fileset(local.custom_library_path, "**/policy_exemption_*.{yml,yml.tftpl,yaml,yaml.tftpl}")) : null
}

# If Policy Assignment files exist, load content into dataset
locals {
  custom_policy_exemptions_dataset_from_json = try(length(local.custom_policy_exemptions_from_json) > 0, false) ? {
    for filepath in local.custom_policy_exemptions_from_json :
    filepath => jsondecode(templatefile("${local.custom_library_path}/${filepath}", local.template_file_vars))
  } : null
  custom_policy_exemptions_dataset_from_yaml = try(length(local.custom_policy_exemptions_from_yaml) > 0, false) ? {
    for filepath in local.custom_policy_exemptions_from_yaml :
    filepath => yamldecode(templatefile("${local.custom_library_path}/${filepath}", local.template_file_vars))
  } : null
}

# If Policy Assignment datasets exist, convert to map
locals {
  custom_policy_exemptions_map_from_json = try(length(local.custom_policy_exemptions_dataset_from_json) > 0, false) ? {
    for key, value in local.custom_policy_exemptions_dataset_from_json :
    value.name => value
    if value.type == local.resource_types.policy_exemption
  } : null
  custom_policy_exemptions_map_from_yaml = try(length(local.custom_policy_exemptions_dataset_from_yaml) > 0, false) ? {
    for key, value in local.custom_policy_exemptions_dataset_from_yaml :
    value.name => value
    if value.type == local.resource_types.policy_exemption
  } : null
}

# Merge the Policy Assignment maps into a single map.
# If duplicates exist due to a custom Policy Assignment being
# defined to override a built-in definition, this is handled by
# merging the custom policies after the built-in policies.
locals {
  archetype_policy_exemptions_map = merge(
    local.custom_policy_exemptions_map_from_json,
    local.custom_policy_exemptions_map_from_yaml,
  )
}

# Generate a map of parameters from the archetype definition and merge
# with the parameters provided using var.parameters.
# Used to determine the parameter values for Policy Assignments.
locals {
  exemptions_parameter_overrides_at_scope = {
    # The following logic merges parameter values from the archetype definition
    # with custom values provided through the parameters input variable.
    for policy_name in toset(keys(merge(
      local.archetype_definition.archetype_config.parameters,
      local.parameters,
    ))) :
    policy_name => merge(
      lookup(local.archetype_definition.archetype_config.parameters, policy_name, null),
      lookup(local.parameters, policy_name, null),
    )
  }
}

# Extract the desired Policy Assignment from archetype_policy_exemptions_map.
locals {
  archetype_policy_exemptions_output = [
    for policy_exemption in local.archetype_policy_exemptions_list :
    {
      resource_id = "${local.provider_path.policy_exemption}${policy_exemption}"
      scope_id    = local.scope_id
      template    = local.archetype_policy_exemptions_map[policy_exemption]
      # Parameter values are finally merged from the policy assignment template
      # with the values provided through other configuration scopes.
      # parameters = merge(
      #   lookup(local.archetype_policy_exemptions_map, policy_exemption, local.parameter_map_default).properties.parameters,
      #   {
      #     for parameter_key, parameter_value in lookup(local.exemptions_parameter_overrides_at_scope, policy_exemption, local.empty_map) :
      #     parameter_key => {
      #       value = parameter_value
      #     }
      #   }
      # )
      # The following attribute is used to control the enforcement mode
      # on Policy Assignments, allowing the template values to be
      # over-written with dynamic values generated by the module, or
      # default to true when neither exist (as per default platform
      # behaviour).
      # exemption_category = coalesce(
      #   try(local.exemption_category[policy_exemption], null),
      #   try(lower(local.archetype_policy_exemptions_map[policy_exemption].properties.exemptionCategory) == "waiver", false) ? true : null,
      #   try(lower(local.archetype_policy_exemptions_map[policy_exemption].properties.exemptionCategory) == "mitigated", false) ? false : null,
      #   true,
      # )
    }
  ]
}
