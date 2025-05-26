# Assign Azure AD roles to security groups
resource "azuread_directory_role_assignment" "tier_role_assignments" {
  for_each = azuread_group.tier_role_groups
  
  role_id             = each.value.role_id
  principal_object_id = azuread_group.tier_role_groups[each.key].object_id
}

# Assign Global Admin to break-glass accounts
resource "azuread_directory_role_assignment" "break_glass_global_admin" {
  count = length(azuread_user.break_glass_accounts)
  
  role_id             = "62e90394-69f5-4237-9190-012177145e10" # Global Administrator
  principal_object_id = azuread_user.break_glass_accounts[count.index].object_id
}