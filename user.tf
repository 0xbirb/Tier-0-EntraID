# Get user objects for assignment
data "azuread_user" "tier_users" {
  for_each = toset(flatten([
    for tier_name, tier_assignments in var.tier_user_assignments : [
      for role_key, users in tier_assignments : users
    ]
  ]))
  
  user_principal_name = each.value
}

# Assign users to groups (this is what was missing in the original!)
resource "azuread_group_member" "tier_user_assignments" {
  for_each = merge([
    for tier_name, tier_assignments in var.tier_user_assignments : {
      for role_key, users in tier_assignments : [
        for user in users :
        "${tier_name}-${role_key}-${user}" => {
          group_object_id = azuread_group.tier_role_groups["${tier_name}-${role_key}"].object_id
          user_object_id  = data.azuread_user.tier_users[user].object_id
        }
      ]
    }
  ]...)
  
  group_object_id  = each.value.group_object_id
  member_object_id = each.value.user_object_id
}

# Create break-glass accounts (separate from regular admin accounts)
resource "azuread_user" "break_glass_accounts" {
  count = var.break_glass_config.create_accounts ? var.break_glass_config.account_count : 0
  
  user_principal_name = "breakglass${count.index + 1}@${var.organization_name}.onmicrosoft.com"
  display_name        = "Break Glass Account ${count.index + 1}"
  mail_nickname       = "breakglass${count.index + 1}"
  password            = "TempPassword123!" # Should be changed immediately
  
  # Use variable to control if accounts are enabled by default
  account_enabled = var.break_glass_config.enable_by_default
  
  # Force password change on first sign-in
  force_change_password_next_sign_in = true
}