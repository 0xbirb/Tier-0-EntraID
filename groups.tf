# Enhanced groups.tf with Cloud Administrator support

# Existing Security Groups (keeping backwards compatibility)
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
  
  # Groups will be added to Administrative Units via explicit membership
}

# Cloud Administrator Dynamic Groups (new feature)
resource "azuread_group" "cloud_admin_groups" {
  for_each = var.enable_lifecycle_management ? var.tier_definitions : {}
  
  display_name     = "${var.organization_name}-${upper(each.key)}-CloudAdmins"
  description      = "Cloud Administrator accounts for ${each.value.description}"
  security_enabled = true
  mail_enabled     = false
  
  # Dynamic membership based on naming convention
  types = ["DynamicMembership"]
  
  dynamic_membership {
    enabled = true
    rule    = join(" ", [
      "(user.userPrincipalName -startsWith \"${var.cloud_admin_naming_convention.prefix}-\")",
      "and (user.userPrincipalName -contains \"-${each.key}-\")",
      "and (user.userPrincipalName -endsWith \"-${var.cloud_admin_naming_convention.suffix}@${var.organization_name}.onmicrosoft.com\")",
      "and (user.accountEnabled -eq true)"
    ])
  }
  
  # Required for role assignments
  assignable_to_role = true
  
  prevent_duplicate_names = true
  
  lifecycle {
    prevent_destroy = true
  }
}

# Primary Account Groups for Cloud Admin eligibility
resource "azuread_group" "cloud_admin_eligible" {
  for_each = var.enable_lifecycle_management ? var.tier_definitions : {}
  
  display_name     = "${var.organization_name}-${upper(each.key)}-CloudAdmin-Eligible"
  description      = "Primary accounts eligible to request cloud administrator accounts for ${each.value.description}"
  security_enabled = true
  
  prevent_duplicate_names = true
  
  # This will be manually managed or synchronized from on-premises
  lifecycle {
    prevent_destroy = true
  }
}

# Cloud Admin Role Assignment Groups (for PIM)
resource "azuread_group" "cloud_admin_role_groups" {
  for_each = var.enable_lifecycle_management ? merge([
    for tier_name, tier in var.tier_definitions : {
      for role_key, role in tier.roles :
      "${tier_name}-${role_key}-cloudadmin" => {
        tier_name   = tier_name
        role_key    = role_key
        role_id     = role.role_id
        description = role.description
      }
    }
  ]...) : {}
  
  display_name = "${var.organization_name}-${upper(each.value.tier_name)}-CloudAdmin-${each.value.description}"
  description  = "Cloud Admins eligible for ${each.value.description} in ${upper(each.value.tier_name)}"
  
  security_enabled   = true
  assignable_to_role = true
  
  prevent_duplicate_names = true
  
  lifecycle {
    prevent_destroy = true
  }
}

# Monitoring groups for security purposes (enhanced)
resource "azuread_group" "dangerous_permissions_monitoring" {
  display_name     = "${var.organization_name}-Dangerous-Graph-Permissions-Monitor"
  description      = "Service principals with dangerous Graph API permissions - requires monitoring"
  security_enabled = true
  
  prevent_duplicate_names = true
}

resource "azuread_group" "vm_contributors_monitor" {
  display_name     = "${var.organization_name}-VM-Contributors-Monitor"
  description      = "Users with VM Contributor role - operational role requiring RunCommand monitoring"
  security_enabled = true
  
  prevent_duplicate_names = true
}

# Cloud Admin specific monitoring groups
resource "azuread_group" "cloud_admin_monitoring" {
  count = var.enable_lifecycle_management ? 1 : 0
  
  display_name     = "${var.organization_name}-CloudAdmin-Activity-Monitor"
  description      = "Monitor all cloud administrator account activities"
  security_enabled = true
  
  prevent_duplicate_names = true
}

resource "azuread_group" "cloud_admin_lifecycle_monitor" {
  count = var.enable_lifecycle_management ? 1 : 0
  
  display_name     = "${var.organization_name}-CloudAdmin-Lifecycle-Monitor"
  description      = "Monitor cloud administrator account creation, modification, and deletion"
  security_enabled = true
  
  prevent_duplicate_names = true
}

# Security Operations Center (SOC) notification group
resource "azuread_group" "soc_notification_group" {
  display_name     = "${var.organization_name}-SOC-Notifications"
  description      = "Security Operations Center team for critical security notifications"
  security_enabled = true
  mail_enabled     = true
  mail_nickname    = "${lower(var.organization_name)}-soc"
  
  prevent_duplicate_names = true
}

# Approval groups for tier-0 operations
resource "azuread_group" "tier0_approval_group" {
  count = var.enable_lifecycle_management ? 1 : 0
  
  display_name     = "${var.organization_name}-Tier0-Approvers"
  description      = "Authorized approvers for Tier-0 administrative operations"
  security_enabled = true
  
  prevent_duplicate_names = true
  
  lifecycle {
    prevent_destroy = true
  }
}

# Output group information
output "security_group_ids" {
  description = "Object IDs of all security groups"
  value = {
    tier_role_groups = {
      for k, v in azuread_group.tier_role_groups : k => {
        id           = v.id
        object_id    = v.object_id
        display_name = v.display_name
      }
    }
    cloud_admin_groups = var.enable_lifecycle_management ? {
      for k, v in azuread_group.cloud_admin_groups : k => {
        id           = v.id
        object_id    = v.object_id
        display_name = v.display_name
        member_count = length(v.members)
      }
    } : {}
    monitoring_groups = {
      dangerous_permissions = {
        id           = azuread_group.dangerous_permissions_monitoring.id
        object_id    = azuread_group.dangerous_permissions_monitoring.object_id
        display_name = azuread_group.dangerous_permissions_monitoring.display_name
      }
      vm_contributors = {
        id           = azuread_group.vm_contributors_monitor.id
        object_id    = azuread_group.vm_contributors_monitor.object_id
        display_name = azuread_group.vm_contributors_monitor.display_name
      }
      soc_notifications = {
        id           = azuread_group.soc_notification_group.id
        object_id    = azuread_group.soc_notification_group.object_id
        display_name = azuread_group.soc_notification_group.display_name
      }
    }
  }
}