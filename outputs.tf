# Main tier structure output
output "tier_structure" {
  description = "Overview of created tier structure"
  value = {
    for tier_name, tier in var.tier_definitions : tier_name => {
      description = tier.description
      roles       = keys(tier.roles)
      groups_created = [
        for role_key in keys(tier.roles) :
        azuread_group.tier_role_groups["${tier_name}-${role_key}"].display_name
      ]
      administrative_unit = azuread_administrative_unit.tier_units[tier_name].display_name
    }
  }
}

# User assignments for verification
output "user_assignments" {
  description = "Users assigned to each tier and role"
  value = var.tier_user_assignments
}

# Administrative Units summary
output "administrative_units" {
  description = "Created Administrative Units for each tier"
  value = {
    for tier_name, au in azuread_administrative_unit.tier_units : tier_name => {
      id           = au.id
      object_id    = au.object_id
      display_name = au.display_name
      description  = au.description
    }
  }
}

# Security groups summary
output "tier_groups" {
  description = "Security groups created for each role in each tier"
  value = {
    for key, group in azuread_group.tier_role_groups : key => {
      id           = group.id
      object_id    = group.object_id
      display_name = group.display_name
      description  = group.description
    }
  }
}

# Conditional Access policies summary
output "conditional_access_policies" {
  description = "Conditional Access policies created for tiering enforcement"
  value = {
    tier0_block_non_paw = {
      id           = azuread_conditional_access_policy.tier0_block_non_paw.id
      display_name = azuread_conditional_access_policy.tier0_block_non_paw.display_name
      state        = azuread_conditional_access_policy.tier0_block_non_paw.state
    }
    tier0_paw_strong_auth = {
      id           = azuread_conditional_access_policy.tier0_paw_strong_auth.id
      display_name = azuread_conditional_access_policy.tier0_paw_strong_auth.display_name
      state        = azuread_conditional_access_policy.tier0_paw_strong_auth.state
    }
    tier1_strong_auth = {
      id           = azuread_conditional_access_policy.tier1_strong_auth.id
      display_name = azuread_conditional_access_policy.tier1_strong_auth.display_name
      state        = azuread_conditional_access_policy.tier1_strong_auth.state
    }
    tier2_strong_auth = {
      id           = azuread_conditional_access_policy.tier2_strong_auth.id
      display_name = azuread_conditional_access_policy.tier2_strong_auth.display_name
      state        = azuread_conditional_access_policy.tier2_strong_auth.state
    }
    break_glass = var.break_glass_config.create_accounts ? {
      id           = azuread_conditional_access_policy.break_glass_emergency_access[0].id
      display_name = azuread_conditional_access_policy.break_glass_emergency_access[0].display_name
      state        = azuread_conditional_access_policy.break_glass_emergency_access[0].state
    } : null
  }
}

# Break-glass accounts (sensitive)
output "break_glass_accounts" {
  description = "Break-glass emergency access accounts"
  value = var.break_glass_config.create_accounts ? {
    for idx, account in azuread_user.break_glass_accounts : idx => {
      id                  = account.id
      object_id          = account.object_id
      user_principal_name = account.user_principal_name
      display_name       = account.display_name
    }
  } : {}
  sensitive = true
}

# Security monitoring information
output "security_monitoring" {
  description = "Security monitoring recommendations and queries"
  value = {
    monitoring_group_id = azuread_group.dangerous_permissions_monitoring.object_id
    kql_queries        = local.monitoring_queries
    tier0_permissions  = var.tier0_graph_permissions
    emergency_procedures = local.emergency_procedures
  }
}

# Named locations summary
output "named_locations" {
  description = "Named locations configured for trusted access"
  value = {
    for name, location in azuread_named_location.trusted_locations : name => {
      id           = location.id
      display_name = location.display_name
      ip_ranges    = location.ip[0].ip_ranges
      trusted      = location.ip[0].trusted
    }
  }
}

# Deployment summary
output "deployment_summary" {
  description = "Summary of the tiering deployment"
  value = {
    tiers_created         = length(var.tier_definitions)
    total_groups          = length(azuread_group.tier_role_groups)
    total_users_assigned  = local.has_users ? length(data.azuread_user.tier_users) : 0
    ca_policies           = 4
    administrative_units  = length(azuread_administrative_unit.tier_units)
    trusted_locations     = length(var.trusted_locations)
    break_glass_accounts  = var.break_glass_config.create_accounts ? length(azuread_user.break_glass_accounts) : 0
    monitored_permissions = length(var.tier0_graph_permissions)
  }
}