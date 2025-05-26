# Note: Authentication Strength Policies require Azure AD Premium P1/P2
# For now, using standard MFA instead of custom phishing-resistant policy

# Conditional Access Policy for Tier-0 (STRICT: PAW + Phishing Resistant Auth REQUIRED)
resource "azuread_conditional_access_policy" "tier0_paw_enforcement" {
  display_name = "${var.organization_name}-Tier0-PAW-Required"
  state        = "enabled"
  
  conditions {
    client_app_types = ["all"]
    
    users {
      included_groups = [
        for key, group in azuread_group.tier_role_groups : group.object_id
        if startswith(key, "tier-0")
      ]
    }
    
    applications {
      included_applications = ["All"]
    }
    
    # BLOCK if NOT from PAW devices
    devices {
      filter {
        mode = "exclude"  # Exclude (allow) only these devices
        rule = "device.deviceId -in [\"${join("\", \"", var.paw_device_ids)}\"]"
      }
    }
    
    locations {
      included_locations = [for loc in azuread_named_location.trusted_locations : loc.id]
    }
  }
  
  # BLOCK access if conditions above are not met
  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}

# Conditional Access Policy for Tier-0 (ALLOW from PAW with Phishing Resistant Auth)
resource "azuread_conditional_access_policy" "tier0_paw_allow" {
  display_name = "${var.organization_name}-Tier0-PAW-Allow-Phishing-Resistant"
  state        = "enabled"
  
  conditions {
    client_app_types = ["all"]
    
    users {
      included_groups = [
        for key, group in azuread_group.tier_role_groups : group.object_id
        if startswith(key, "tier-0")
      ]
    }
    
    applications {
      included_applications = ["All"]
    }
    
    # ONLY from PAW devices
    devices {
      filter {
        mode = "include"  # Include (apply to) only these devices
        rule = "device.deviceId -in [\"${join("\", \"", var.paw_device_ids)}\"]"
      }
    }
    
    locations {
      included_locations = [for loc in azuread_named_location.trusted_locations : loc.id]
    }
  }
  
  grant_controls {
    operator          = "AND"
    built_in_controls = ["mfa", "compliantDevice"]
  }
  
  session_controls {
    sign_in_frequency        = var.tier_definitions["tier-0"].session_timeout_hours
    sign_in_frequency_period = "hours"
    persistent_browser_mode  = "never"
  }
}

# Conditional Access Policy for Tier-1 (Phishing Resistant Auth Required)
resource "azuread_conditional_access_policy" "tier1_phishing_resistant" {
  display_name = "${var.organization_name}-Tier1-Phishing-Resistant-Required"
  state        = "enabled"
  
  conditions {
    client_app_types = ["all"]
    
    users {
      included_groups = [
        for key, group in azuread_group.tier_role_groups : group.object_id
        if startswith(key, "tier-1")
      ]
    }
    
    applications {
      included_applications = ["All"]
    }
    
    locations {
      included_locations = [for loc in azuread_named_location.trusted_locations : loc.id]
    }
  }
  
  grant_controls {
    operator          = "AND"
    built_in_controls = ["mfa", "compliantDevice"]
  }
  
  session_controls {
    sign_in_frequency        = var.tier_definitions["tier-1"].session_timeout_hours
    sign_in_frequency_period = "hours"
  }
}

# Conditional Access Policy for Tier-2 (Phishing Resistant Auth Required)
resource "azuread_conditional_access_policy" "tier2_phishing_resistant" {
  display_name = "${var.organization_name}-Tier2-Phishing-Resistant-Required"
  state        = "enabled"
  
  conditions {
    client_app_types = ["all"]
    
    users {
      included_groups = [
        for key, group in azuread_group.tier_role_groups : group.object_id
        if startswith(key, "tier-2")
      ]
    }
    
    applications {
      included_applications = ["All"]
    }
    
    locations {
      included_locations = [for loc in azuread_named_location.trusted_locations : loc.id]
    }
  }
  
  grant_controls {
    operator          = "AND"
    built_in_controls = ["mfa", "compliantDevice"]
  }
  
  session_controls {
    sign_in_frequency        = var.tier_definitions["tier-2"].session_timeout_hours
    sign_in_frequency_period = "hours"
  }
}

# Block legacy authentication for all privileged accounts
resource "azuread_conditional_access_policy" "block_legacy_auth" {
  display_name = "${var.organization_name}-Block-Legacy-Auth-Privileged"
  state        = "enabled"
  
  conditions {
    users {
      included_groups = [for group in azuread_group.tier_role_groups : group.object_id]
    }
    
    client_app_types = ["exchangeActiveSync", "other"]
    
    applications {
      included_applications = ["All"]
    }
  }
  
  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}

# Break-glass emergency access policy (TRUE emergency access)
resource "azuread_conditional_access_policy" "break_glass_emergency_access" {
  count = var.break_glass_config.create_accounts ? 1 : 0
  
  display_name = "${var.organization_name}-Break-Glass-Emergency-Access"
  state        = "enabled"
  
  conditions {
    client_app_types = ["all"]
    
    users {
      included_users = [for user in azuread_user.break_glass_accounts : user.object_id]
    }
    
    applications {
      included_applications = ["All"]
    }
    
    # NO location restrictions - emergency can happen anywhere
    # NO device restrictions - emergency might be from any device
  }
  
  grant_controls {
    operator          = "AND"
    built_in_controls = ["mfa"]  # Regular MFA only - not phishing-resistant
    # No device compliance requirement for true emergency access
  }
  
  session_controls {
    sign_in_frequency        = 1
    sign_in_frequency_period = "hours"
    persistent_browser_mode  = "never"
  }
}

# Alternative: More secure break-glass with conditional location bypass
resource "azuread_conditional_access_policy" "break_glass_secure_emergency" {
  display_name = "${var.organization_name}-Break-Glass-Secure-Emergency"
  state        = "disabled"  # Enable this if you want more restrictive break-glass
  
  conditions {
    users {
      included_users = [for user in azuread_user.break_glass_accounts : user.object_id]
    }
    
    applications {
      included_applications = ["All"]
    }
    
    # Apply stricter controls when accessing from trusted locations
    locations {
      included_locations = [for loc in azuread_named_location.trusted_locations : loc.id]
    }
  }
  
  grant_controls {
    operator                    = "AND"
    built_in_controls          = []
    authentication_strength_id = azuread_authentication_strength_policy.phishing_resistant.id
  }
  
  session_controls {
    sign_in_frequency        = 1
    sign_in_frequency_period = "hours"
    persistent_browser_mode  = "never"
  }
}