# terraform.tfvars.example
# Copy this file to terraform.tfvars and customize with your values
# DO NOT commit terraform.tfvars to version control as it contains secrets!

# =============================================================================
# Service Principal Authentication (Required)
# =============================================================================
# Create a service principal in Azure AD with sufficient permissions
# See README.md for required permissions
client_id     = "12345678-1234-1234-1234-123456789012"  # Your Azure AD App Registration Client ID
client_secret = "your-super-secret-client-secret-here"   # Your Azure AD App Registration Secret
tenant_id     = "87654321-4321-4321-4321-210987654321"  # Your Azure AD Tenant ID

# =============================================================================
# Organization Configuration
# =============================================================================
organization_name = "yourcompany"  # Will be used in resource names (e.g., yourcompany-TIER0-Global-Administrator)

# =============================================================================
# User Assignments (Customize with your actual users)
# =============================================================================
# IMPORTANT: Users must already exist in your Azure AD tenant
# Start with empty lists [] to deploy infrastructure first, then add users later
tier_user_assignments = {
  "tier-0" = {
    # Most privileged roles - require PAW devices
    "global-admin"           = ["admin@yourcompany.onmicrosoft.com"]
    "privileged-auth-admin"  = ["auth-admin@yourcompany.onmicrosoft.com"]
    "privileged-role-admin"  = ["role-admin@yourcompany.onmicrosoft.com"]
    "application-admin"      = ["app-admin@yourcompany.onmicrosoft.com"]
    "intune-admin"           = ["intune-admin@yourcompany.onmicrosoft.com"]
  }
  
  "tier-1" = {
    # Identity and resource administration - require PAW devices
    "user-admin"     = ["user-admin@yourcompany.onmicrosoft.com"]
    "security-admin" = ["security-admin@yourcompany.onmicrosoft.com"]
    "exchange-admin" = ["exchange-admin@yourcompany.onmicrosoft.com"]
  }
  
  "tier-2" = {
    # Workstation and application administration - standard devices
    "helpdesk-admin" = ["helpdesk@yourcompany.onmicrosoft.com"]
    "groups-admin"   = ["groups-admin@yourcompany.onmicrosoft.com"]
  }
}

# =============================================================================
# Privileged Access Workstation (PAW) Configuration
# =============================================================================
# Device IDs of workstations allowed for Tier-0 and Tier-1 access
# Get these from Azure AD > Devices > [Device Name] > Device ID
paw_device_ids = [
  "11111111-2222-3333-4444-555555555555",  # PAW-ADMIN-01
  "66666666-7777-8888-9999-000000000000",  # PAW-ADMIN-02
]

# =============================================================================
# Trusted Network Locations
# =============================================================================
# IP ranges considered trusted for administrative access
# These will be used in Conditional Access policies
trusted_locations = [
  {
    name       = "Corporate-Headquarters"
    ip_ranges  = ["203.0.113.0/24"]  # Replace with your actual public IP range
    is_trusted = true
  },
  {
    name       = "Branch-Office"
    ip_ranges  = ["198.51.100.0/26"]  # Replace with your actual public IP range
    is_trusted = true
  },
  {
    name       = "VPN-Endpoint"
    ip_ranges  = ["192.0.2.0/28"]     # Replace with your VPN exit IP range
    is_trusted = true
  }
]

# =============================================================================
# Break-Glass Emergency Account Configuration
# =============================================================================
break_glass_config = {
  create_accounts           = true   # Set to false if you don't want break-glass accounts
  account_count            = 2       # Number of break-glass accounts to create
  enable_by_default        = false   # Accounts will be disabled by default (enable during emergencies)
  require_phishing_resistant = false  # Use regular MFA for emergency access
  allow_from_any_location  = true    # Emergency access from any location
}

# =============================================================================
# Optional: Additional Configuration
# =============================================================================
# These may be required depending on your terraform.tfvars content
# Remove if not needed
app_type                = "web"
permissions_description = "Azure AD Tiering Implementation"

# =============================================================================
# Usage Instructions:
# =============================================================================
# 1. Copy this file to terraform.tfvars
# 2. Replace all placeholder values with your actual values
# 3. Start with empty user assignment lists [] to deploy infrastructure first
# 4. Get your service principal permissions right (see README.md)
# 5. Run: tofu plan
# 6. Run: tofu apply
# 7. Add users to the lists incrementally after infrastructure is deployed
#
# Security Notes:
# - Never commit terraform.tfvars to version control
# - Use strong, unique passwords for service principals
# - Regularly rotate service principal secrets
# - Monitor privileged access usage through Azure AD audit logs
# - Test break-glass procedures regularly
# 
# Required Service Principal Permissions:
# - Global Administrator (or combination of):
#   - User Administrator
#   - Groups Administrator  
#   - Application Administrator
#   - Conditional Access Administrator
#   - Privileged Role Administrator