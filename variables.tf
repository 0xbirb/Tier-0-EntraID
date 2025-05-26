variable "organization_name" {
  description = "Name of the organization for resource naming"
  type        = string
  default     = "devacp"
}

# Optional: Service Principal authentication variables
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

variable "tier_definitions" {
  description = "Simplified tier definitions with roles and security requirements"
  type = map(object({
    description               = string
    requires_paw             = bool
    session_timeout_hours    = number
    roles = map(object({
      role_id     = string
      description = string
    }))
  }))
  
  default = {
    "tier-0" = {
      description            = "Domain and Enterprise Administration"
      requires_paw          = true
      session_timeout_hours = 1
      roles = {
        "global-admin" = {
          role_id     = "62e90394-69f5-4237-9190-012177145e10"
          description = "Global Administrator"
        }
        "privileged-auth-admin" = {
          role_id     = "7be44c8a-adaf-4e2a-84d6-ab2649e08a13"
          description = "Privileged Authentication Administrator"
        }
        "privileged-role-admin" = {
          role_id     = "e8611ab8-c189-46e8-94e1-60213ab1f814"
          description = "Privileged Role Administrator"
        }
        "application-admin" = {
          role_id     = "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
          description = "Application Administrator"
        }
        "intune-admin" = {
          role_id     = "3a2c62db-5318-420d-8d74-23affee5d9d5"
          description = "Intune Administrator"
        }
      }
    }
    
    "tier-1" = {
      description            = "Identity and Resource Administration"
      requires_paw          = true
      session_timeout_hours = 4
      roles = {
        "user-admin" = {
          role_id     = "fe930be7-5e62-47db-91af-98c3a49a38b1"
          description = "User Administrator"
        }
        "exchange-admin" = {
          role_id     = "29232cdf-9323-42fd-ade2-1d097af3e4de"
          description = "Exchange Administrator"
        }
        "security-admin" = {
          role_id     = "194ae4cb-b126-40b2-bd5b-6091b380977d"
          description = "Security Administrator"
        }
      }
    }
    
    "tier-2" = {
      description            = "Workstation and Application Administration"
      requires_paw          = false
      session_timeout_hours = 8
      roles = {
        "helpdesk-admin" = {
          role_id     = "729827e3-9c14-49f7-bb1b-9608f156bbb8"
          description = "Helpdesk Administrator"
        }
        "groups-admin" = {
          role_id     = "fdd7a751-b60b-444a-984c-02652fe8fa1c"
          description = "Groups Administrator"
        }
      }
    }
  }
}

variable "tier_user_assignments" {
  description = "Users to assign to each tier and role - modify this to assign users"
  type = map(map(list(string)))
  
  default = {
    "tier-0" = {
      "global-admin"           = [] # Add your Global Admin users here
      "privileged-auth-admin"  = [] # Add your Privileged Auth Admin users here
      "application-admin"      = [] # Add your Application Admin users here
      "intune-admin"           = [] # Add your Intune Admin users here
    }
    "tier-1" = {
      "user-admin"     = [] # Add your User Admin users here
      "security-admin" = [] # Add your Security Admin users here
      "exchange-admin" = [] # Add your Exchange Admin users here
    }
    "tier-2" = {
      "helpdesk-admin" = [] # Add your Helpdesk Admin users here
      "groups-admin"   = [] # Add your Groups Admin users here
    }
  }
}

variable "paw_device_ids" {
  description = "List of Privileged Access Workstation device IDs allowed for tier 0 access"
  type        = list(string)
  default = [
    "12345678-1234-1234-1234-123456789012", # PAW-ADMIN-01
    "87654321-4321-4321-4321-210987654321", # PAW-ADMIN-02
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
    create_accounts           = true
    account_count            = 2
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