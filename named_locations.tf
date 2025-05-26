# Create trusted named locations for Conditional Access
resource "azuread_named_location" "trusted_locations" {
  for_each = { for loc in var.trusted_locations : loc.name => loc }
  
  display_name = each.value.name
  ip {
    ip_ranges_ipv4 = each.value.ip_ranges
    trusted        = each.value.is_trusted
  }
}