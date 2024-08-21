<!-- markdownlint-disable first-line-h1 -->
## Overview

This page describes how to use the module to configure an Azure Policy Exemption



>**IMPORTANT**: To allow the declaration of custom or expanded templates, you must create a custom library folder within the root module and include the path to this folder using the `library_path` variable within the module configuration. In our example, the directory is `lib`.

## Create Policy Exemption template file

In your `lib` directory create a `policy_exemptions` subdirectory if you don't already have one. You can learn more about archetypes and custom libraries in [this article](https://github.com/Azure/terraform-azurerm-caf-enterprise-scale/wiki/%5BUser-Guide%5D-Archetype-Definitions).

> **NOTE:** Creating a `policy_exemptions` subdirectory is a recommendation only. If you prefer not to create one or to call it something else, the role assignment will still work.

In the `policy_exemptions` subdirectory, create a `policy_exemption_waiver_exempt_xyz.tmpl.json.tftpl` file.

> **NOTE:** If you reuse an existing name, this policy exemption will override the default policy exemption from the shared module library.

Copy the bellow code into the `policy_exemption_waiver_exempt_xyz.tmpl.json.tftpl` file.

```json
${jsonencode(
  {
  "apiVersion": "2022-07-01-preview", // azapi provider is used so you can define whole object in properties. Schema validation is on so you must specify properties which are valid for defined version. If not defined '2022-07-01-preview' is used
  "name": "Exempt-XYZ",
  "scope": "${current_scope_resource_id}", //This will be used as parent for exemption it can bed ID of subscription or resource group or resource. If not defined parent will be assigned archetype
  "type": "Microsoft.Authorization/policyExemptions",
  "properties": {
      "displayName": "Exemption XYZ",
      "description": "Exempt XYZ",
      "metadata": {
          "requestedBy": "Adrea Andrea",
          "approvedBy": "Jonas Jonas",
          "approvedOn": "2024-08-09T09:27:00.0000000Z",
          "emailRef": "Ref to email subject of approval"
      },
      "policyAssignmentId": "/providers/Microsoft.Management/managementGroups/landing-zones/providers/Microsoft.Authorization/policyAssignments/Deny-CreateOfPublicIP",
      "policyDefinitionReferenceIds": [
          "88c0b9da-ce96-4b03-9635-f29a937e2900"
      ],
      "exemptionCategory": "Waiver",
      "assignmentScopeValidation": "Default"
  }
}
)}

```

## Trigger the deployment

You should now kick-off your Terraform workflow (init, plan, apply) again to apply the updated configuration. This can be done either locally or through a pipeline.
When your workflow has finished, the `Exempt-XYZ` policy exemption will be assigned at the defined scope.

```hcl
# module.enterprise_scale.azapi_resource.policy_exemption["/providers/Microsoft.Management/managementGroups/root/providers/Microsoft.Authorization/policyExemptions/Exempt-XYZ"] will be created
  + resource "azapi_resource" "policy_exemption" {
      + body                      = jsonencode(
            {
              + properties = {
                  + assignmentScopeValidation    = "Default"
                  + description                  = "Exemption to allow IP forwarding for Nutanix Flow Gateways VMs, required for the Nutanix cluster configuration."
                  + displayName                  = "Exemption for Nutanix Flow Gateways"
                  + exemptionCategory            = "Waiver"
                  + metadata                     = {
                      + approvedBy  = "Jonas Jonas"
                      + approvedOn  = "2024-08-09T09:27:00.0000000Z"
                      + emailRef    = "Ref to email subject of approval"
                      + requestedBy = "Adrea Andrea"
                    }
                  + policyAssignmentId           = "/providers/Microsoft.Management/managementGroups/landing-zones/providers/Microsoft.Authorization/policyAssignments/Deny-CreateOfPublicIP"
                  + policyDefinitionReferenceIds = [
                      + "88c0b9da-ce96-4b03-9635-f29a937e2900",
                    ]
                }
            }
        )
      + id                        = (known after apply)
      + ignore_casing             = false
      + ignore_missing_property   = true
      + name                      = "Exempt-XYZ"
      + output                    = (known after apply)
      + parent_id                 = "/providers/Microsoft.Management/managementGroups/plx"
      + removing_special_chars    = false
      + schema_validation_enabled = true
      + type                      = "Microsoft.Authorization/policyExemptions@2022-07-01-preview"
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```
