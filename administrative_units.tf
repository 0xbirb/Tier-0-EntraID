# Create Administrative Units (one per tier)
resource "azuread_administrative_unit" "tier_units" {
  for_each = var.tier_definitions
  
  display_name = "${var.organization_name}-${upper(each.key)}-AU"
  description  = "${each.value.description} Administrative Unit"
  
  prevent_duplicate_names = true
}

# Create Administrative Unit for AAD Connect sync accounts
resource "azuread_administrative_unit" "aad_connect_au" {
  display_name = "${var.organization_name}-AADConnect-Sync-AU"
  description  = "Administrative Unit for AAD Connect sync accounts - requires special monitoring"
  
  prevent_duplicate_names = true
}