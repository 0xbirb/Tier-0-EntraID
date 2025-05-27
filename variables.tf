# Enhanced variables.tf - Add these to your existing variables.tf file


variable "cloud_admin_naming_convention" {
  description = "Naming convention for cloud administrator accounts"
  type = object({
    prefix = string
    suffix = string
  })
  default = {
    prefix = "cadm"
    suffix = "admin"
  }
}

variable "primary_account_domain" {
  description = "Domain for primary user accounts that can create cloud admin accounts"
  type        = string
  default     = ""
}

variable "enable_management_restricted_au" {
  description = "Enable Management Restricted Administrative Units (requires setup permissions)"
  type        = bool
  default     = true
}

variable "enable_pim_configuration" {
  description = "Enable Privileged Identity Management configuration for cloud admins"
  type        = bool
  default     = false
}

variable "cloud_admin_authentication_strength" {
  description = "Authentication methods allowed for cloud administrators"
  type = object({
    require_phishing_resistant = bool
    allowed_methods = list(string)
  })
  default = {
    require_phishing_resistant = true
    allowed_methods = [
      "windowsHelloForBusiness",
      "fido2",
      "x509CertificateMultiFactor"
    ]
  }
}




#  ENHANCED TIER DEFINITIONS 

variable "enhanced_tier_definitions" {
  description = "Enhanced tier definitions with cloud admin support"
  type = map(object({
    description               = string
    requires_paw             = bool
    session_timeout_hours    = number
    enable_cloud_admins      = bool
    max_cloud_admins         = number
    require_approval         = bool
    approval_group_id        = string
    roles = map(object({
      role_id     = string
      description = string
      is_permanent = bool
      max_duration_hours = number
    }))
  }))
  
  default = {
    "tier-0" = {
      description            = "Domain and Enterprise Administration"
      requires_paw          = true
      session_timeout_hours = 1
      enable_cloud_admins   = true
      max_cloud_admins      = 10
      require_approval      = true
      approval_group_id     = ""
      roles = {
        "global-admin" = {
          role_id     = "62e90394-69f5-4237-9190-012177145e10"
          description = "Global Administrator"
          is_permanent = false
          max_duration_hours = 4
        }
        "privileged-auth-admin" = {
          role_id     = "7be44c8a-adaf-4e2a-84d6-ab2649e08a13"
          description = "Privileged Authentication Administrator"
          is_permanent = false
          max_duration_hours = 4
        }
        "privileged-role-admin" = {
          role_id     = "e8611ab8-c189-46e8-94e1-60213ab1f814"
          description = "Privileged Role Administrator"
          is_permanent = false
          max_duration_hours = 4
        }
        "application-admin" = {
          role_id     = "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
          description = "Application Administrator"
          is_permanent = false
          max_duration_hours = 8
        }
        "intune-admin" = {
          role_id     = "3a2c62db-5318-420d-8d74-23affee5d9d5"
          description = "Intune Administrator"
          is_permanent = false
          max_duration_hours = 8
        }
        }
        "user-admin" = {
          role_id     = "3a2c62db-5318-420d-8d74-23affee5d9d5"
          description = "User Administrator"
          is_permanent = false
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
          role_id     = "fe930be7-5e62-47db-91af-98c3a49a38b1"
          description = "User Administrator"
          is_permanent = false
          max_duration_hours = 8
        }
        "exchange-admin" = {
          role_id     = "29232cdf-9323-42fd-ade2-1d097af3e4de"
          description = "Exchange Administrator"
          is_permanent = false
          max_duration_hours = 8
        }
        "security-admin" = {
          role_id     = "194ae4cb-b126-40b2-bd5b-6091b380977d"
          description = "Security Administrator"
          is_permanent = false
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
          role_id     = "729827e3-9c14-49f7-bb1b-9608f156bbb8"
          description = "Helpdesk Administrator"
          is_permanent = true
          max_duration_hours = 0
        }
        "groups-admin" = {
          role_id     = "fdd7a751-b60b-444a-984c-02652fe8fa1c"
          description = "Groups Administrator"
          is_permanent = true
          max_duration_hours = 0
        }
      }
    }
  }
}



# ===== EXISTING VARIABLES (keeping backwards compatibility) =====

variable "organization_name" {
  description = "Name of the organization for resource naming"
  type        = string
  default     = "devacp"
}

variable "client_id" {
  description = "Azure AD Application (client) ID for service principal authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "client_secret" {
  description = "Azure AD Application client secret for service principal authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "app_type" {
  description = "Application type (from terraform.tfvars)"
  type        = string
  default     = ""
}

variable "permissions_description" {
  description = "Permissions description (from terraform.tfvars)"
  type        = string
  default     = ""
}

variable "paw_device_ids" {
  description = "List of Privileged Access Workstation device IDs allowed for tier 0 access"
  type        = list(string)
  default = [
    "12345678-1234-1234-1234-123456789012",
    "87654321-4321-4321-4321-210987654321",
  ]
}

variable "break_glass_config" {
  description = "Configuration for break-glass emergency accounts"
  type = object({
    create_accounts           = bool
    account_count            = number
    enable_by_default        = bool
    require_phishing_resistant = bool
    allow_from_any_location  = bool
  })
  
  default = {
    create_accounts           = false
    account_count            = 1
    enable_by_default        = false
    require_phishing_resistant = false
    allow_from_any_location  = true
  }
}

variable "trusted_locations" {
  description = "Named locations (IP ranges) considered trusted for administrative access"
  type = list(object({
    name         = string
    ip_ranges    = list(string)
    is_trusted   = bool
  }))
  default = [
    {
      name       = "Corporate-HQ"
      ip_ranges  = ["203.0.113.0/24", "198.51.100.0/24"]
      is_trusted = true
    },
    {
      name       = "DR-Site"
      ip_ranges  = ["192.0.2.0/24"]
      is_trusted = true
    }
  ]
}

variable "tier0_graph_permissions" {
  description = "Graph API permissions that provide direct or indirect paths to Global Admin"
  type = map(object({
    permission_id = string
    description   = string
    attack_path   = string
  }))
  
  default = {
    "RoleManagement.ReadWrite.Directory" = {
      permission_id = "9e3f62cf-ca93-4989-b6ce-bf83c28f9fe8"
      description   = "Can assign Global Admin role to service principals"
      attack_path   = "Direct - Assign Global Admin role to compromised service principal"
    }
    "Application.ReadWrite.All" = {
      permission_id = "1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9"
      description   = "Can create credentials for service principals with dangerous permissions"
      attack_path   = "Indirect - Create credentials for SP with RoleManagement.ReadWrite.Directory"
    }
    "AppRoleAssignment.ReadWrite.All" = {
      permission_id = "06b708a9-e830-4db3-a914-8e69da51d44f"
      description   = "Can grant dangerous permissions to service principals"
      attack_path   = "Indirect - Grant RoleManagement.ReadWrite.Directory to compromised SP"
    }
    "UserAuthenticationMethod.ReadWrite.All" = {
      permission_id = "50f7ac38-4987-43ac-910c-8d6bac4ca2b8"
      description   = "Can create Temporary Access Pass for any user including Global Admins"
      attack_path   = "Indirect - Create TAP for break-glass account and authenticate as Global Admin"
    }
  }
}