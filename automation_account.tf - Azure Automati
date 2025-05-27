# automation_account.tf - Azure Automation Account for Cloud Admin Lifecycle Management

# Create Resource Group if it doesn't exist
resource "azurerm_resource_group" "automation_rg" {
  count = var.enable_lifecycle_management && var.resource_group_name != "" ? 1 : 0
  
  name     = var.resource_group_name
  location = var.azure_location
  
  tags = {
    Purpose     = "Cloud Administrator Lifecycle Management"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# Azure Automation Account
resource "azurerm_automation_account" "cloud_admin_lifecycle" {
  count = var.enable_lifecycle_management ? 1 : 0
  
  name                = "${var.organization_name}-cloudadmin-automation"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  sku_name           = var.automation_account_config.sku_name
  
  identity {
    type = "SystemAssigned"
  }
  
  public_network_access_enabled = false
  
  tags = {
    Purpose     = "Cloud Administrator Lifecycle Management"
    Environment = "Production"
    ManagedBy   = "Terraform"
    SecurityTier = "Tier-0"
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "automation_logs" {
  count = var.enable_lifecycle_management && var.automation_account_config.enable_diagnostic_settings ? 1 : 0
  
  name                = "${var.organization_name}-cloudadmin-logs"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.monitoring_config.log_retention_days
  
  tags = {
    Purpose     = "Cloud Administrator Automation Logging"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# Diagnostic Settings for Automation Account
resource "azurerm_monitor_diagnostic_setting" "automation_diagnostics" {
  count = var.enable_lifecycle_management && var.automation_account_config.enable_diagnostic_settings ? 1 : 0
  
  name               = "${var.organization_name}-automation-diagnostics"
  target_resource_id = azurerm_automation_account.cloud_admin_lifecycle[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.automation_logs[0].id
  
  enabled_log {
    category = "JobLogs"
  }
  
  enabled_log {
    category = "JobStreams"
  }
  
  enabled_log {
    category = "DscNodeStatus"
  }
  
  metric {
    category = "AllMetrics"
  }
}

# Assign Azure RBAC permissions to Managed Identity
resource "azurerm_role_assignment" "automation_reader" {
  count = var.enable_lifecycle_management ? 1 : 0
  
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Reader"
  principal_id         = azurerm_automation_account.cloud_admin_lifecycle[0].identity[0].principal_id
}

# Assign Entra directory roles to Managed Identity
resource "azuread_directory_role_assignment" "automation_user_admin" {
  count = var.enable_lifecycle_management ? 1 : 0
  
  role_id             = "fe930be7-5e62-47db-91af-98c3a49a38b1" # User Administrator
  principal_object_id = azurerm_automation_account.cloud_admin_lifecycle[0].identity[0].principal_id
}

resource "azuread_directory_role_assignment" "automation_groups_admin" {
  count = var.enable_lifecycle_management ? 1 : 0
  
  role_id             = "fdd7a751-b60b-444a-984c-02652fe8fa1c" # Groups Administrator
  principal_object_id = azurerm_automation_account.cloud_admin_lifecycle[0].identity[0].principal_id
}

resource "azuread_directory_role_assignment" "automation_license_admin" {
  count = var.enable_lifecycle_management ? 1 : 0
  
  role_id             = "4d6ac14f-3453-41d0-bef9-a3e0c569773a" # License Administrator
  principal_object_id = azurerm_automation_account.cloud_admin_lifecycle[0].identity[0].principal_id
}

resource "azuread_directory_role_assignment" "automation_directory_readers" {
  count = var.enable_lifecycle_management ? 1 : 0
  
  role_id             = "88d8e3e3-8f55-4a1e-953a-9b9898b8876b" # Directory Readers
  principal_object_id = azurerm_automation_account.cloud_admin_lifecycle[0].identity[0].principal_id
}

# Create App Registration for Graph API permissions
resource "azuread_application" "automation_app" {
  count = var.enable_lifecycle_management ? 1 : 0
  
  display_name = "${var.organization_name}-cloudadmin-automation-app"
  owners       = [data.azuread_client_config.current.object_id]
  
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
    
    # Application permissions
    resource_access {
      id   = "19dbc75e-c2e2-444c-a770-ec69d8559fc7" # Directory.ReadWrite.All
      type = "Role"
    }
    
    resource_access {
      id   = "62a82d76-70ea-41e2-9197-370581804d09" # Group.ReadWrite.All
      type = "Role"
    }
    
    resource_access {
      id   = "741f803b-c850-494e-b5df-cde7c675a1ca" # User.ReadWrite.All
      type = "Role"
    }
    
    resource_access {
      id   = "1138cb37-bd11-4084-a2b7-9f71582aeddb" # Device.ReadWrite.All
      type = "Role"
    }
    
    resource_access {
      id   = "50483e42-d915-4231-9639-7fdb7fd190e5" # UserAuthenticationMethod.ReadWrite.All
      type = "Role"
    }
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# Service Principal for the application
resource "azuread_service_principal" "automation_sp" {
  count = var.enable_lifecycle_management ? 1 : 0
  
  client_id                    = azuread_application.automation_app[0].client_id
  app_role_assignment_required = true
  owners                       = [data.azuread_client_config.current.object_id]
  
  lifecycle {
    prevent_destroy = true
  }
}

# Grant admin consent for Graph API permissions
resource "azuread_app_role_assignment" "automation_graph_permissions" {
  for_each = var.enable_lifecycle_management ? toset([
    "19dbc75e-c2e2-444c-a770-ec69d8559fc7", # Directory.ReadWrite.All
    "62a82d76-70ea-41e2-9197-370581804d09", # Group.ReadWrite.All
    "741f803b-c850-494e-b5df-cde7c675a1ca", # User.ReadWrite.All
    "1138cb37-bd11-4084-a2b7-9f71582aeddb", # Device.ReadWrite.All
    "50483e42-d915-4231-9639-7fdb7fd190e5", # UserAuthenticationMethod.ReadWrite.All
  ]) : toset([])
  
  app_role_id         = each.value
  principal_object_id = azurerm_automation_account.cloud_admin_lifecycle[0].identity[0].principal_id
  resource_object_id  = azuread_service_principal.automation_sp[0].object_id
}

# Automation Variables
locals {
  automation_variables = {
    # Administrative Unit IDs
    "CloudAdmin_Tier0_AU_Id" = azuread_administrative_unit.cloud_admin_units["tier-0"].object_id
    "CloudAdmin_Tier1_AU_Id" = azuread_administrative_unit.cloud_admin_units["tier-1"].object_id
    "CloudAdmin_Tier2_AU_Id" = azuread_administrative_unit.cloud_admin_units["tier-2"].object_id
    
    # Group IDs
    "CloudAdmin_Tier0_Group_Id" = azuread_group.cloud_admin_groups["tier-0"].object_id
    "CloudAdmin_Tier1_Group_Id" = azuread_group.cloud_admin_groups["tier-1"].object_id
    "CloudAdmin_Tier2_Group_Id" = azuread_group.cloud_admin_groups["tier-2"].object_id
    
    # Eligible Groups
    "CloudAdmin_Tier0_Eligible_Group_Id" = azuread_group.cloud_admin_eligible["tier-0"].object_id
    "CloudAdmin_Tier1_Eligible_Group_Id" = azuread_group.cloud_admin_eligible["tier-1"].object_id
    "CloudAdmin_Tier2_Eligible_Group_Id" = azuread_group.cloud_admin_eligible["tier-2"].object_id
    
    # Naming Convention
    "CloudAdmin_Naming_Prefix" = var.cloud_admin_naming_convention.prefix
    "CloudAdmin_Naming_Suffix" = var.cloud_admin_naming_convention.suffix
    "CloudAdmin_Domain"        = "${var.organization_name}.onmicrosoft.com"
    
    # Configuration
    "CloudAdmin_Max_Tier0_Accounts" = tostring(var.enhanced_tier_definitions["tier-0"].max_cloud_admins)
    "CloudAdmin_Max_Tier1_Accounts" = tostring(var.enhanced_tier_definitions["tier-1"].max_cloud_admins)
    "CloudAdmin_Max_Tier2_Accounts" = tostring(var.enhanced_tier_definitions["tier-2"].max_cloud_admins)
    
    # Monitoring
    "CloudAdmin_SOC_Group_Id"        = azuread_group.soc_notification_group.object_id
    "CloudAdmin_Monitor_Group_Id"    = azuread_group.cloud_admin_monitoring[0].object_id
    "CloudAdmin_Approval_Group_Id"   = azuread_group.tier0_approval_group[0].object_id
  }
}

resource "azurerm_automation_variable_string" "config_vars" {
  for_each = var.enable_lifecycle_management ? local.automation_variables : {}
  
  name                    = each.key
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.cloud_admin_lifecycle[0].name
  value                   = each.value
  encrypted               = false
  description             = "Configuration variable for Cloud Administrator lifecycle management"
}

# Encrypted variables for sensitive data
resource "azurerm_automation_variable_string" "encrypted_vars" {
  for_each = var.enable_lifecycle_management ? {
    "CloudAdmin_BreakGlass_Password" = "TempP@ssw0rd!ChangeMe"
  } : {}
  
  name                    = each.key
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.cloud_admin_lifecycle[0].name
  value                   = each.value
  encrypted               = true
  description             = "Encrypted configuration variable"
}

# Output automation account details
output "automation_account_details" {
  description = "Azure Automation Account details"
  value = var.enable_lifecycle_management ? {
    id                   = azurerm_automation_account.cloud_admin_lifecycle[0].id
    name                 = azurerm_automation_account.cloud_admin_lifecycle[0].name
    identity_principal_id = azurerm_automation_account.cloud_admin_lifecycle[0].identity[0].principal_id
    identity_tenant_id    = azurerm_automation_account.cloud_admin_lifecycle[0].identity[0].tenant_id
    resource_group       = var.resource_group_name
    location             = var.azure_location
  } : null
  sensitive = false
}