# Enhanced administrative_units.tf with Management Restricted capabilities

# Create Management Restricted Administrative Units (one per tier)
resource "azuread_administrative_unit" "tier_units" {
  for_each = var.tier_definitions
  
  display_name = "${var.organization_name}-${upper(each.key)}-AU"
  description  = "${each.value.description} Administrative Unit"
  
  # Make Administrative Units RESTRICTED - Enhanced security
  hidden_membership_enabled = var.enable_management_restricted_au
  
  prevent_duplicate_names = true
  
  # Add lifecycle management
  lifecycle {
    prevent_destroy = true
  }
}

# Create Cloud Admin specific Administrative Units (if lifecycle management enabled)
resource "azuread_administrative_unit" "cloud_admin_units" {
  for_each = var.enable_lifecycle_management ? var.tier_definitions : {}
  
  display_name = "${var.organization_name}-${upper(each.key)}-CloudAdmin-AU"
  description  = "Cloud Administrator accounts for ${each.value.description}"
  
  # Management Restricted for maximum security
  hidden_membership_enabled = true
  
  prevent_duplicate_names = true
  
  lifecycle {
    prevent_destroy = true
  }
}

# Administrative Unit Restricted Management Scope - Role Groups
resource "azuread_administrative_unit_member" "tier_group_members" {
  for_each = azuread_group.tier_role_groups
  
  administrative_unit_object_id = azuread_administrative_unit.tier_units[
    # Extract tier name correctly: "tier-0-global-admin" -> "tier-0"
    join("-", slice(split("-", each.key), 0, 2))
  ].object_id
  member_object_id = each.value.object_id
}

# Administrative Unit Restricted Management Scope - Cloud Admin Groups
resource "azuread_administrative_unit_member" "cloud_admin_group_members" {
  for_each = var.enable_lifecycle_management ? azuread_group.cloud_admin_groups : {}
  
  administrative_unit_object_id = azuread_administrative_unit.cloud_admin_units[each.key].object_id
  member_object_id = each.value.object_id
}

# Create Administrative Unit for AAD Connect sync accounts - RESTRICTED
resource "azuread_administrative_unit" "aad_connect_au" {
  display_name = "${var.organization_name}-AADConnect-Sync-AU"
  description  = "Administrative Unit for AAD Connect sync accounts - requires special monitoring"
  
  # Make Administrative Unit RESTRICTED
  hidden_membership_enabled = true
  
  prevent_duplicate_names = true
  
  lifecycle {
    prevent_destroy = true
  }
}

# Create Administrative Unit for Service Principals with dangerous permissions
resource "azuread_administrative_unit" "dangerous_permissions_au" {
  count = var.enable_lifecycle_management ? 1 : 0
  
  display_name = "${var.organization_name}-DangerousPermissions-AU"
  description  = "Service Principals with tier-0 equivalent permissions"
  
  # Maximum restriction
  hidden_membership_enabled = true
  
  prevent_duplicate_names = true
  
  lifecycle {
    prevent_destroy = true
  }
}

# Scoped role assignments for AU management
resource "azuread_directory_role_assignment" "au_user_admin" {
  for_each = var.enable_management_restricted_au ? var.tier_definitions : {}
  
  role_id             = "fe930be7-5e62-47db-91af-98c3a49a38b1" # User Administrator
  principal_object_id = azuread_group.tier_role_groups["${each.key}-user-admin"].object_id
  directory_scope_id  = azuread_administrative_unit.tier_units[each.key].object_id
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "azuread_directory_role_assignment" "au_groups_admin" {
  for_each = var.enable_management_restricted_au ? var.tier_definitions : {}
  
  role_id             = "fdd7a751-b60b-444a-984c-02652fe8fa1c" # Groups Administrator
  principal_object_id = azuread_group.tier_role_groups["${each.key}-groups-admin"].object_id
  directory_scope_id  = azuread_administrative_unit.tier_units[each.key].object_id
  
  lifecycle {
    create_before_destroy = true
  }
}

# Cloud Admin AU specific role assignments
resource "azuread_directory_role_assignment" "cloud_admin_au_user_admin" {
  for_each = var.enable_lifecycle_management ? var.tier_definitions : {}
  
  role_id             = "fe930be7-5e62-47db-91af-98c3a49a38b1" # User Administrator
  principal_object_id = azurerm_automation_account.cloud_admin_lifecycle[0].identity[0].principal_id
  directory_scope_id  = azuread_administrative_unit.cloud_admin_units[each.key].object_id
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "azuread_directory_role_assignment" "cloud_admin_au_license_admin" {
  for_each = var.enable_lifecycle_management ? var.tier_definitions : {}
  
  role_id             = "4d6ac14f-3453-41d0-bef9-a3e0c569773a" # License Administrator
  principal_object_id = azurerm_automation_account.cloud_admin_lifecycle[0].identity[0].principal_id
  directory_scope_id  = azuread_administrative_unit.cloud_admin_units[each.key].object_id
  
  lifecycle {
    create_before_destroy = true
  }
}

# Output for tracking AU IDs
output "administrative_unit_ids" {
  description = "Object IDs of created Administrative Units"
  value = {
    tier_units = {
      for k, v in azuread_administrative_unit.tier_units : k => {
        id           = v.id
        object_id    = v.object_id
        display_name = v.display_name
      }
    }
    cloud_admin_units = var.enable_lifecycle_management ? {
      for k, v in azuread_administrative_unit.cloud_admin_units : k => {
        id           = v.id
        object_id    = v.object_id
        display_name = v.display_name
      }
    } : {}
    aad_connect = {
      id           = azuread_administrative_unit.aad_connect_au.id
      object_id    = azuread_administrative_unit.aad_connect_au.object_id
      display_name = azuread_administrative_unit.aad_connect_au.display_name
    }
    dangerous_permissions = var.enable_lifecycle_management ? {
      id           = azuread_administrative_unit.dangerous_permissions_au[0].id
      object_id    = azuread_administrative_unit.dangerous_permissions_au[0].object_id
      display_name = azuread_administrative_unit.dangerous_permissions_au[0].display_name
    } : null
  }
  sensitive = false
}