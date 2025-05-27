# terraform.tfvars.example - Enhanced with Cloud Admin Lifecycle Management
# Copy this file to terraform.tfvars and customize with your values

# ===== AUTHENTICATION =====
# Service Principal Authentication
client_id     = "12345678-1234-1234-1234-123456789012"
client_secret = "your-super-secret-client-secret-here"
tenant_id     = "87654321-4321-4321-4321-210987654321"

# ===== ORGANIZATION CONFIGURATION =====
organization_name = "yourcompany"

# ===== CLOUD ADMIN LIFECYCLE MANAGEMENT =====
# Enable the new lifecycle management features
enable_lifecycle_management = true

# Cloud Administrator naming convention
cloud_admin_naming_convention = {
  prefix = "cadm"
  suffix = "admin"
}

# Primary account domain (for hybrid environments)
primary_account_domain = "yourcompany.com"

# Enable Management Restricted Administrative Units
enable_management_restricted_au = true

# ===== AZURE RESOURCES =====
# Azure region for automation resources
azure_location = "eastus2"

# Resource group for Azure Automation
resource_group_name = "rg-cloudadmin-automation-prod"

# Subscription ID for Azure resources
subscription_id = "f47626a6-2970-41a8-b44c-a4a14ccff181"

# ===== AUTOMATION CONFIGURATION =====
automation_account_config = {
  sku_name                   = "Basic"
  enable_diagnostic_settings = true
  log_analytics_workspace_id = ""  # Will be created automatically
}

# ===== ENHANCED TIER DEFINITIONS =====
# Use enhanced_tier_definitions for cloud admin support
enhanced_tier_definitions = {
  "tier-0" = {
    description            = "Domain and Enterprise Administration"
    requires_paw          = true
    session_timeout_hours = 1
    enable_cloud_admins   = true
    max_cloud_admins      = 10
    require_approval      = true
    approval_group_id     = ""  # Will be populated after group creation
    roles = {
      "global-admin" = {
        role_id            = "62e90394-69f5-4237-9190-012177145e10"
        description        = "Global Administrator"
        is_permanent       = false
        max_duration_hours = 4
      }
      "privileged-auth-admin" = {
        role_id            = "7be44c8a-adaf-4e2a-84d6-ab2649e08a13"
        description        = "Privileged Authentication Administrator"
        is_permanent       = false
        max_duration_hours = 4
      }
      "privileged-role-admin" = {
        role_id            = "e8611ab8-c189-46e8-94e1-60213ab1f814"
        description        = "Privileged Role Administrator"
        is_permanent       = false
        max_duration_hours = 4
      }
      "application-admin" = {
        role_id            = "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
        description        = "Application Administrator"
        is_permanent       = false
        max_duration_hours = 8
      }
      "intune-admin" = {
        role_id            = "3a2c62db-5318-420d-8d74-23affee5d9d5"
        description        = "Intune Administrator"
        is_permanent       = false
        max_duration_hours = 8
      }
    }
  }
  
  "tier-1" = {
    description            = "Identity and Resource Administration"
    requires_paw          = true
    session_timeout_hours = 4
    enable_cloud_admins   = true
    max_cloud_admins      = 20
    require_approval      = false
    approval_group_id     = ""
    roles = {
      "user-admin" = {
        role_id            = "fe930be7-5e62-47db-91af-98c3a49a38b1"
        description        = "User Administrator"
        is_permanent       = false
        max_duration_hours = 8
      }
      "exchange-admin" = {
        role_id            = "29232cdf-9323-42fd-ade2-1d097af3e4de"
        description        = "Exchange Administrator"
        is_permanent       = false
        max_duration_hours = 8
      }
      "security-admin" = {
        role_id            = "194ae4cb-b126-40b2-bd5b-6091b380977d"
        description        = "Security Administrator"
        is_permanent       = false
        max_duration_hours = 8
      }
    }
  }
  
  "tier-2" = {
    description            = "Workstation and Application Administration"
    requires_paw          = false
    session_timeout_hours = 8
    enable_cloud_admins   = true
    max_cloud_admins      = 50
    require_approval      = false
    approval_group_id     = ""
    roles = {
      "helpdesk-admin" = {
        role_id            = "729827e3-9c14-49f7-bb1b-9608f156bbb8"
        description        = "Helpdesk Administrator"
        is_permanent       = true
        max_duration_hours = 0
      }
      "groups-admin" = {
        role_id            = "fdd7a751-b60b-444a-984c-02652fe8fa1c"
        description        = "Groups Administrator"
        is_permanent       = true
        max_duration_hours = 0
      }
    }
  }
}

# ===== EXISTING USER ASSIGNMENTS =====
# Keep your existing user assignments for backwards compatibility
tier_user_assignments = {
  "tier-0" = {
    "global-admin"          = ["admin@yourcompany.onmicrosoft.com"]
    "privileged-auth-admin" = ["auth-admin@yourcompany.onmicrosoft.com"]
    "privileged-role-admin" = ["role-admin@yourcompany.onmicrosoft.com"]
    "application-admin"     = ["app-admin@yourcompany.onmicrosoft.com"]
    "intune-admin"          = ["intune-admin@yourcompany.onmicrosoft.com"]
  }
  "tier-1" = {
    "user-admin"     = ["user-admin@yourcompany.onmicrosoft.com"]
    "security-admin" = ["security-admin@yourcompany.onmicrosoft.com"]
    "exchange-admin" = ["exchange-admin@yourcompany.onmicrosoft.com"]
  }
  "tier-2" = {
    "helpdesk-admin" = ["helpdesk@yourcompany.onmicrosoft.com"]
    "groups-admin"   = ["groups-admin@yourcompany.onmicrosoft.com"]
  }
}

# ===== PAW CONFIGURATION =====
# PAW Device IDs (get from Azure AD > Devices)
paw_device_ids = [
  "11111111-2222-3333-4444-555555555555",  # PAW-ADMIN-01
  "66666666-7777-8888-9999-000000000000",  # PAW-ADMIN-02
  "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",  # PAW-ADMIN-03
  "ffffffff-0000-1111-2222-333333333333",  # PAW-ADMIN-04
]

# ===== TRUSTED LOCATIONS =====
trusted_locations = [
  {
    name       = "Corporate-HQ"
    ip_ranges  = ["203.0.113.0/24"]
    is_trusted = true
  },
  {
    name       = "Branch-Office"
    ip_ranges  = ["198.51.100.0/26"]
    is_trusted = true
  },
  {
    name       = "DR-Site"
    ip_ranges  = ["192.0.2.0/24"]
    is_trusted = true
  }
]

# ===== BREAK-GLASS CONFIGURATION =====
break_glass_config = {
  create_accounts            = true
  account_count             = 2
  enable_by_default         = false
  require_phishing_resistant = false
  allow_from_any_location   = true
}

# ===== AUTHENTICATION STRENGTH =====
cloud_admin_authentication_strength = {
  require_phishing_resistant = true
  allowed_methods = [
    "windowsHelloForBusiness",
    "fido2",
    "x509CertificateMultiFactor",
    "microsoftAuthenticatorPush"  # Optional: if you want to allow Authenticator
  ]
}

# ===== CLOUD ADMIN LICENSES =====
cloud_admin_license_config = {
  assign_licenses = true
  license_skus = [
    {
      sku_id         = "EXCHANGEDESKLESS"  # Exchange Online Kiosk
      disabled_plans = []
    },
    {
      sku_id         = "AAD_PREMIUM_P2"    # Azure AD Premium P2 (if needed)
      disabled_plans = []
    }
  ]
}

# ===== MONITORING CONFIGURATION =====
monitoring_config = {
  enable_monitoring           = true
  alert_email_addresses      = ["security-team@yourcompany.com", "soc@yourcompany.com"]
  log_retention_days         = 90
  enable_sentinel_integration = false  # Set to true if you have Sentinel
}

# ===== COMPLIANCE CONFIGURATION =====
compliance_config = {
  require_attestation        = true
  attestation_frequency_days = 90
  max_inactive_days         = 30
  require_training          = true
}

# ===== PIM CONFIGURATION =====
enable_pim_configuration = true

# ===== ADDITIONAL CONFIGURATION =====
app_type                = "web"
permissions_description = "Azure AD Tiering Implementation with Cloud Admin Lifecycle Management"

# ===== REQUIRED PERMISSIONS FOR SETUP =====
# The service principal or user running this Terraform configuration needs:
#
# Azure Roles:
# - Contributor (at subscription or resource group level)
# - User Access Administrator (optional, for role assignments)
#
# Entra Directory Roles:
# - Cloud Application Administrator
# - Privileged Role Administrator
# - User Administrator (scoped to AUs after creation)
# - Groups Administrator (scoped to AUs after creation)
# - License Administrator (scoped to AUs after creation)
#
# For full lifecycle management, after initial setup:
# - The Automation Account's Managed Identity handles most operations
# - Tier-0 admins manage the Automation Account and runbooks
# - Cloud admin accounts are created/managed through automation