# terraform.tfvars.example
# Copy this file to terraform.tfvars and customize with your values

# Service Principal Authentication
client_id     = "12345678-1234-1234-1234-123456789012"
client_secret = "your-super-secret-client-secret-here"
tenant_id     = "87654321-4321-4321-4321-210987654321"

# Organization Configuration
organization_name = "yourcompany"

# User Assignments (must exist in Azure AD)
tier_user_assignments = {
  "tier-0" = {
    "global-admin"           = ["admin@yourcompany.onmicrosoft.com"]
    "privileged-auth-admin"  = ["auth-admin@yourcompany.onmicrosoft.com"]
    "privileged-role-admin"  = ["role-admin@yourcompany.onmicrosoft.com"]
    "application-admin"      = ["app-admin@yourcompany.onmicrosoft.com"]
    "intune-admin"           = ["intune-admin@yourcompany.onmicrosoft.com"]
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

# PAW Device IDs (get from Azure AD > Devices)
paw_device_ids = [
  "11111111-2222-3333-4444-555555555555",
  "66666666-7777-8888-9999-000000000000",
]

# Trusted IP Ranges
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
  }
]

# Break-Glass Configuration
break_glass_config = {
  create_accounts           = true
  account_count            = 2
  enable_by_default        = false
  require_phishing_resistant = false
  allow_from_any_location  = true
}

# Additional Variables
app_type                = "web"
permissions_description = "Azure AD Tiering Implementation"

# Required Service Principal Roles:
# - Global Administrator
# OR the combination of:
# - User Administrator
# - Groups Administrator
# - Application Administrator
# - Conditional Access Administrator
# - Privileged Role Administrator
# - Directory Readers