
# Authentication Strength Policy for Admins
resource "azuread_authentication_strength_policy" "cloud_admin" {
  count = var.enable_lifecycle_management && var.cloud_admin_authentication_strength.require_phishing_resistant ? 1 : 0
  
  display_name = "${var.organization_name}-CloudAdmin-AuthStrength"
  description  = "Phishing-resistant authentication required for cloud administrators"
  
  allowed_combinations = var.cloud_admin_authentication_strength.allowed_methods
}

# Authentication Strength Policy for Tier-0 (strictest)
resource "azuread_authentication_strength_policy" "tier0_auth_strength" {
  display_name = "${var.organization_name}-Tier0-AuthStrength"
  description  = "Strictest authentication for Tier-0 administrators"
  
  allowed_combinations = [
    "windowsHelloForBusiness",
    "fido2",
    "x509CertificateMultiFactor"
  ]
}

resource "azuread_authentication_context_class_reference" "pim_activation" {
  count = var.enable_pim_configuration ? 1 : 0
  
  display_name = "${var.organization_name}-PIM-Activation"
  description  = "Required for activating privileged roles"
  is_available = true
}


# Conditional Access Policy for Tier-0 (STRICT: PAW + Phishing Resistant Auth REQUIRED)
resource "azuread_conditional_access_policy" "tier0_paw_enforcement" {
  display_name = "${var.organization_name}-Tier0-PAW-Required"
  state        = "enabled"
  
  conditions {
    client_app_types = ["all"]
    
    users {
      included_groups = concat(
        [for key, group in azuread_group.tier_role_groups : group.object_id if startswith(key, "tier-0")],
        var.enable_lifecycle_management ? [azuread_group.cloud_admin_groups["tier-0"].object_id] : []
      )
    }
    
    applications {
      included_applications = ["All"]
    }
    
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
      included_groups = concat(
        [for key, group in azuread_group.tier_role_groups : group.object_id if startswith(key, "tier-0")],
        var.enable_lifecycle_management ? [azuread_group.cloud_admin_groups["tier-0"].object_id] : []
      )
    }
    
    applications {
      included_applications = ["All"]
    }
    
    devices {
      filter {
        mode = "include" 
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
    authentication_strength_policy_id = azuread_authentication_strength_policy.tier0_auth_strength.id
  }
  
  session_controls {
    sign_in_frequency        = var.tier_definitions["tier-0"].session_timeout_hours
    sign_in_frequency_period = "hours"
    persistent_browser_mode  = "never"
    
    # Cloud apps security
    cloud_app_security_policy = "mcasConfigured"
  }
}

# NEW: Cloud Administrator Specific Policies

resource "azuread_conditional_access_policy" "cloud_admin_auth_context" {
  count = var.enable_lifecycle_management ? 1 : 0
  
  display_name = "${var.organization_name}-CloudAdmin-AuthContext"
  state        = "enabled"
  
  conditions {
    client_app_types = ["all"]
    
    users {
      included_groups = [
        for key, group in azuread_group.cloud_admin_groups : group.object_id
      ]
    }
    
    applications {
      included_applications = ["All"]
    }
    
    authentication_context {
      id = azuread_authentication_context_class_reference.pim_activation[0].id
    }
  }
  
  grant_controls {
    operator = "AND"
    built_in_controls = ["mfa"]
    authentication_strength_policy_id = azuread_authentication_strength_policy.cloud_admin[0].id
  }
  
  session_controls {
    sign_in_frequency        = 1
    sign_in_frequency_period = "hours"
    persistent_browser_mode  = "never"
    
    # Continuous access evaluation
    continuous_access_evaluation_mode = "strictEnforcement"
  }
}

# ENHANCED EXISTING POLICIES

# Conditional Access Policy for Tier-1 (Enhanced with Cloud Admin support)
resource "azuread_conditional_access_policy" "tier1_phishing_resistant" {
  display_name = "${var.organization_name}-Tier1-Phishing-Resistant-Required"
  state        = "enabled"
  
  conditions {
    client_app_types = ["all"]
    
    users {
      included_groups = concat(
        [for key, group in azuread_group.tier_role_groups : group.object_id if startswith(key, "tier-1")],
        var.enable_lifecycle_management ? [azuread_group.cloud_admin_groups["tier-1"].object_id] : []
      )
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
    persistent_browser_mode  = "never"
  }
}

# Conditional Access Policy for Tier-2 (Enhanced with Cloud Admin support)
resource "azuread_conditional_access_policy" "tier2_phishing_resistant" {
  display_name = "${var.organization_name}-Tier2-Phishing-Resistant-Required"
  state        = "enabled"
  
  conditions {
    client_app_types = ["all"]
    
    users {
      included_groups = concat(
        [for key, group in azuread_group.tier_role_groups : group.object_id if startswith(key, "tier-2")],
        var.enable_lifecycle_management ? [azuread_group.cloud_admin_groups["tier-2"].object_id] : []
      )
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

# Output Conditional Access Policy IDs
output "conditional_access_policy_ids" {
  description = "IDs of created Conditional Access policies"
  value = {
    tier0_paw_enforcement = azuread_conditional_access_policy.tier0_paw_enforcement.id
    tier0_paw_allow = azuread_conditional_access_policy.tier0_paw_allow.id
    tier1_phishing_resistant = azuread_conditional_access_policy.tier1_phishing_resistant.id
    tier2_phishing_resistant = azuread_conditional_access_policy.tier2_phishing_resistant.id
    cloud_admin_policies = var.enable_lifecycle_management ? {
      auth_context = azuread_conditional_access_policy.cloud_admin_auth_context[0].id
      device_restriction = azuread_conditional_access_policy.cloud_admin_device_restriction[0].id
    } : null
    
    break_glass = var.break_glass_config.create_accounts ? azuread_conditional_access_policy.break_glass_emergency_access[0].id : null
  }
}