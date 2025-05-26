# Create Security Groups (simplified logic)
resource "azuread_group" "tier_role_groups" {
  for_each = merge([
    for tier_name, tier in var.tier_definitions : {
      for role_key, role in tier.roles :
      "${tier_name}-${role_key}" => {
        tier_name   = tier_name
        role_key    = role_key
        role_id     = role.role_id
        description = role.description
      }
    }
  ]...)
  
  display_name            = "${var.organization_name}-${upper(each.value.tier_name)}-${each.value.description}"
  description            = "${each.value.description} - ${upper(each.value.tier_name)}"
  security_enabled       = true
  assignable_to_role     = true
  prevent_duplicate_names = true
  
  # Add to appropriate Administrative Unit
  administrative_unit_ids = [azuread_administrative_unit.tier_units[each.value.tier_name].object_id]
}

# Create monitoring groups for security purposes
resource "azuread_group" "dangerous_permissions_monitoring" {
  display_name     = "${var.organization_name}-Dangerous-Graph-Permissions-Monitor"
  description      = "Service principals with dangerous Graph API permissions - requires monitoring"
  security_enabled = true
}

resource "azuread_group" "vm_contributors_monitor" {
  display_name     = "${var.organization_name}-VM-Contributors-Monitor"
  description      = "Users with VM Contributor role - operational role requiring RunCommand monitoring"
  security_enabled = true
}