# Create Administrative Units (one per tier) - RESTRICTED
resource "azuread_administrative_unit" "tier_units" {
  for_each = var.tier_definitions
  
  display_name = "${var.organization_name}-${upper(each.key)}-AU"
  description  = "${each.value.description} Administrative Unit"
  
  # Make Administrative Units RESTRICTED
  hidden_membership_enabled = true
  
  prevent_duplicate_names = true
}

# Administrative Unit Restricted Management Scope
resource "azuread_administrative_unit_member" "tier_group_members" {
  for_each = azuread_group.tier_role_groups
  
  administrative_unit_object_id = azuread_administrative_unit.tier_units[
    # Extract tier name correctly: "tier-0-global-admin" -> "tier-0"
    join("-", slice(split("-", each.key), 0, 2))
  ].object_id
  member_object_id = each.value.object_id
}

# Create Administrative Unit for AAD Connect sync accounts - RESTRICTED
resource "azuread_administrative_unit" "aad_connect_au" {
  display_name = "${var.organization_name}-AADConnect-Sync-AU"
  description  = "Administrative Unit for AAD Connect sync accounts - requires special monitoring"
  
  # Make Administrative Unit RESTRICTED
  hidden_membership_enabled = true
  
  prevent_duplicate_names = true
}