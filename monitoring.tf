# monitoring.tf - Enhanced Security Monitoring for Cloud Administrators

# Data source for current client configuration
data "azuread_client_config" "current" {}

# Create monitoring groups
resource "azuread_group" "cloud_admin_monitoring" {
  display_name     = "${var.organization_name}-CloudAdmin-Monitoring"
  description      = "Group for monitoring cloud administrator activities"
  security_enabled = true
  
  prevent_duplicate_names = true
}

resource "azuread_group" "security_monitoring_group" {
  display_name     = "${var.organization_name}-Security-Monitoring"
  description      = "Security monitoring and alerting group"
  security_enabled = true
  mail_enabled     = true
  mail_nickname    = "${lower(var.organization_name)}-security"
  
  prevent_duplicate_names = true
}

# Alert rules for Azure Monitor (if enabled)
resource "azurerm_monitor_action_group" "security_alerts" {
  count = var.enable_lifecycle_management && var.monitoring_config.enable_monitoring ? 1 : 0
  
  name                = "${var.organization_name}-security-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "SecAlert"
  
  email_receiver {
    name                    = "SecurityTeam"
    email_address           = var.monitoring_config.alert_email_addresses[0]
    use_common_alert_schema = true
  }
  
  dynamic "email_receiver" {
    for_each = slice(var.monitoring_config.alert_email_addresses, 1, length(var.monitoring_config.alert_email_addresses))
    content {
      name                    = "SecurityTeam${email_receiver.key + 2}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }
}

# Log Analytics queries for monitoring
locals {
  cloud_admin_monitoring_queries = {
    # Account lifecycle monitoring
    cloud_admin_creation = {
      query = <<-QUERY
        AuditLogs 
        | where OperationName == "Add user" 
        | where TargetResources[0].userPrincipalName startswith "${var.cloud_admin_naming_convention.prefix}-"
        | project TimeGenerated, 
                  UserPrincipalName = TargetResources[0].userPrincipalName, 
                  InitiatedBy = InitiatedBy.user.userPrincipalName,
                  Result
        | order by TimeGenerated desc
      QUERY
      description = "Monitor creation of cloud administrator accounts"
      severity = "Medium"
    }
    
    cloud_admin_deletion = {
      query = <<-QUERY
        AuditLogs 
        | where OperationName == "Delete user" 
        | where TargetResources[0].userPrincipalName startswith "${var.cloud_admin_naming_convention.prefix}-"
        | project TimeGenerated, 
                  UserPrincipalName = TargetResources[0].userPrincipalName, 
                  InitiatedBy = InitiatedBy.user.userPrincipalName,
                  Result
        | order by TimeGenerated desc
      QUERY
      description = "Monitor deletion of cloud administrator accounts"
      severity = "High"
    }
    
    cloud_admin_modification = {
      query = <<-QUERY
        AuditLogs 
        | where OperationName in ("Update user", "Reset user password", "Change user password")
        | where TargetResources[0].userPrincipalName startswith "${var.cloud_admin_naming_convention.prefix}-"
        | project TimeGenerated, 
                  OperationName,
                  UserPrincipalName = TargetResources[0].userPrincipalName, 
                  InitiatedBy = InitiatedBy.user.userPrincipalName,
                  ModifiedProperties = TargetResources[0].modifiedProperties
        | order by TimeGenerated desc
      QUERY
      description = "Monitor modifications to cloud administrator accounts"
      severity = "Medium"
    }
    
    # Authentication monitoring
    cloud_admin_signin = {
      query = <<-QUERY
        SigninLogs 
        | where UserPrincipalName startswith "${var.cloud_admin_naming_convention.prefix}-" 
        | where ResultType == 0
        | project TimeGenerated, 
                  UserPrincipalName, 
                  AppDisplayName, 
                  IPAddress, 
                  Location, 
                  DeviceDetail,
                  ConditionalAccessStatus
        | order by TimeGenerated desc
      QUERY
      description = "Monitor successful sign-ins by cloud administrators"
      severity = "Low"
    }
    
    cloud_admin_failed_signin = {
      query = <<-QUERY
        SigninLogs 
        | where UserPrincipalName startswith "${var.cloud_admin_naming_convention.prefix}-" 
        | where ResultType != 0
        | project TimeGenerated, 
                  UserPrincipalName, 
                  ResultType, 
                  ResultDescription, 
                  IPAddress, 
                  Location
        | order by TimeGenerated desc
      QUERY
      description = "Monitor failed sign-in attempts by cloud administrators"
      severity = "Medium"
    }
    
    cloud_admin_risky_signin = {
      query = <<-QUERY
        SigninLogs 
        | where UserPrincipalName startswith "${var.cloud_admin_naming_convention.prefix}-"
        | where RiskLevelDuringSignIn != "none" or RiskLevelAggregated != "none"
        | project TimeGenerated, 
                  UserPrincipalName, 
                  RiskLevelDuringSignIn, 
                  RiskLevelAggregated, 
                  RiskDetail, 
                  IPAddress
        | order by TimeGenerated desc
      QUERY
      description = "Monitor risky sign-ins by cloud administrators"
      severity = "High"
    }
    
    # Role activation monitoring
    cloud_admin_role_activation = {
      query = <<-QUERY
        AuditLogs 
        | where OperationName == "Add member to role" 
        | where InitiatedBy.user.userPrincipalName startswith "${var.cloud_admin_naming_convention.prefix}-"
        | extend RoleName = tostring(TargetResources[0].displayName)
        | project TimeGenerated, 
                  InitiatedBy = InitiatedBy.user.userPrincipalName,
                  RoleName,
                  TargetUser = TargetResources[1].userPrincipalName
        | order by TimeGenerated desc
      QUERY
      description = "Monitor role activations by cloud administrators"
      severity = "High"
    }
    
    cloud_admin_role_deactivation = {
      query = <<-QUERY
        AuditLogs 
        | where OperationName == "Remove member from role" 
        | where InitiatedBy.user.userPrincipalName startswith "${var.cloud_admin_naming_convention.prefix}-"
        | extend RoleName = tostring(TargetResources[0].displayName)
        | project TimeGenerated, 
                  InitiatedBy = InitiatedBy.user.userPrincipalName,
                  RoleName,
                  TargetUser = TargetResources[1].userPrincipalName
        | order by TimeGenerated desc
      QUERY
      description = "Monitor role deactivations by cloud administrators"
      severity = "Medium"
    }
    
    # Privilege escalation detection
    tier0_role_assignment_outside_pim = {
      query = <<-QUERY
        AuditLogs 
        | where OperationName == "Add member to role" 
        | extend RoleName = tostring(TargetResources[0].displayName)
        | where RoleName in ("Global Administrator", "Privileged Role Administrator", "Privileged Authentication Administrator")
        | where InitiatedBy.app.displayName != "MS-PIM" // Not through PIM
        | project TimeGenerated, 
                  InitiatedBy = coalesce(InitiatedBy.user.userPrincipalName, InitiatedBy.app.displayName),
                  RoleName,
                  TargetUser = TargetResources[1].userPrincipalName
        | order by TimeGenerated desc
      QUERY
      description = "Detect Tier-0 role assignments outside of PIM"
      severity = "Critical"
    }
    
    # Compliance monitoring
    cloud_admin_inactive_accounts = {
      query = <<-QUERY
        let InactiveDays = ${var.compliance_config.max_inactive_days};
        SigninLogs
        | where TimeGenerated > ago(90d)
        | where UserPrincipalName startswith "${var.cloud_admin_naming_convention.prefix}-"
        | summarize LastSignIn = max(TimeGenerated) by UserPrincipalName
        | where LastSignIn < ago(InactiveDays * 1d)
        | project UserPrincipalName, 
                  LastSignIn, 
                  DaysSinceLastSignIn = datetime_diff('day', now(), LastSignIn)
        | order by DaysSinceLastSignIn desc
      QUERY
      description = "Identify inactive cloud administrator accounts"
      severity = "Medium"
    }
    
    # Automation account monitoring
    automation_runbook_failures = {
      query = <<-QUERY
        AzureDiagnostics
        | where ResourceProvider == "MICROSOFT.AUTOMATION"
        | where Category == "JobLogs"
        | where ResultType == "Failed"
        | project TimeGenerated, 
                  RunbookName_s, 
                  ResultType, 
                  JobId_g, 
                  StreamType_s
        | order by TimeGenerated desc
      QUERY
      description = "Monitor Azure Automation runbook failures"
      severity = "Medium"
    }
    
    automation_account_modifications = {
      query = <<-QUERY
        AzureActivity
        | where ResourceProvider == "Microsoft.Automation"
        | where OperationNameValue contains "write" or OperationNameValue contains "delete"
        | project TimeGenerated, 
                  OperationNameValue, 
                  Caller, 
                  Resource, 
                  ActivityStatusValue
        | order by TimeGenerated desc
      QUERY
      description = "Monitor modifications to Azure Automation account"
      severity = "High"
    }
  }
  
  # Enhanced monitoring queries from existing configuration
  enhanced_monitoring_queries = merge(
    local.cloud_admin_monitoring_queries,
    {
      dangerous_app_permissions = {
        query = jsonencode({
          query = "AuditLogs | where OperationName == 'Add app role assignment to service principal' | where Result =~ 'success' | mv-expand TargetResources | mv-expand TargetResources.modifiedProperties | where TargetResources_modifiedProperties.displayName == 'AppRole.Value' | extend AddedPermission = replace_string(tostring(TargetResources_modifiedProperties.newValue),'\"','') | where AddedPermission in~ ('RoleManagement.ReadWrite.Directory', 'Application.ReadWrite.All', 'AppRoleAssignment.ReadWrite.All')"
          description = "Monitor assignments of dangerous Graph API permissions"
        })
        description = "Monitor assignments of dangerous Graph API permissions"
        severity = "Critical"
      }
      
      service_principal_credential_creation = {
        query = jsonencode({
          query = "AuditLogs | where OperationName == 'Add service principal credentials' | where InitiatedBy.user.userPrincipalName != '' | project TimeGenerated, OperationName, InitiatedBy.user.userPrincipalName, TargetResources[0].displayName"
          description = "Monitor creation of service principal credentials by users"
        })
        description = "Monitor creation of service principal credentials by users"
        severity = "High"
      }
      
      privileged_role_assignments = {
        query = jsonencode({
          query = "AuditLogs | where OperationName == 'Add member to role' | where TargetResources[0].modifiedProperties | extend RoleName = tostring(TargetResources[0].modifiedProperties[1].newValue) | where RoleName in ('Global Administrator', 'Privileged Role Administrator', 'Application Administrator')"
          description = "Monitor assignments to high-privilege roles"
        })
        description = "Monitor assignments to high-privilege roles"
        severity = "High"
      }
      
      azure_elevation_access = {
        query = jsonencode({
          query = "AzureActivity | where OperationNameValue =~ 'Microsoft.Authorization/elevateAccess/action' | extend timestamp = TimeGenerated, AccountCustomEntity = Caller, IPCustomEntity = CallerIpAddress"
          description = "Monitor Global Admin elevation to Azure subscriptions"
        })
        description = "Monitor Global Admin elevation to Azure subscriptions"
        severity = "Critical"
      }
      
      vm_run_command_abuse = {
        query = jsonencode({
          query = "AzureActivity | where CategoryValue == 'Administrative' | where OperationNameValue =~ 'Microsoft.Compute/virtualMachines/runCommand/action' | extend VMName = tostring(todynamic(Properties).resource) | summarize make_list(ActivityStatusValue), TimeGenerated = max(TimeGenerated) by CorrelationId, CallerIpAddress, Caller, ResourceGroup, VMName"
          description = "Monitor VM RunCommand operations for lateral movement"
        })
        description = "Monitor VM RunCommand operations for lateral movement"
        severity = "High"
      }
    }
  )
}

# Create Log Analytics alert rules
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "cloud_admin_alerts" {
  for_each = var.enable_lifecycle_management && var.monitoring_config.enable_monitoring ? local.cloud_admin_monitoring_queries : {}
  
  name                = "${var.organization_name}-alert-${replace(each.key, "_", "-")}"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  
  scopes = [azurerm_log_analytics_workspace.automation_logs[0].id]
  
  description = each.value.description
  enabled     = true
  
  criteria {
    query                   = each.value.query
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
    
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }
  
  window_duration        = "PT5M"
  evaluation_frequency   = "PT5M"
  severity               = each.value.severity == "Critical" ? 0 : (each.value.severity == "High" ? 1 : (each.value.severity == "Medium" ? 2 : 3))
  
  action {
    action_groups = [azurerm_monitor_action_group.security_alerts[0].id]
  }
  
  tags = {
    Purpose = "Cloud Administrator Security Monitoring"
    Tier    = each.value.severity
  }
}

# Sentinel Analytics Rules (if enabled)
resource "azurerm_sentinel_alert_rule_scheduled" "cloud_admin_sentinel_rules" {
  for_each = var.enable_lifecycle_management && var.monitoring_config.enable_sentinel_integration ? local.cloud_admin_monitoring_queries : {}
  
  name                       = "${var.organization_name}-sentinel-${replace(each.key, "_", "-")}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.automation_logs[0].id
  display_name               = each.value.description
  severity                   = each.value.severity
  
  query = each.value.query
  
  entity_mapping {
    entity_type = "Account"
    field_mapping {
      identifier = "FullName"
      column_name = "UserPrincipalName"
    }
  }
  
  tactics = ["PrivilegeEscalation", "DefenseEvasion"]
  
  incident_configuration {
    create_incident = true
    grouping {
      enabled                 = true
      lookback_duration       = "PT5H"
      matching_method         = "AllEntities"
      reopen_closed_incidents = false
    }
  }
  
  event_grouping {
    aggregation_method = "SingleAlert"
  }
  
  alert_rule_template_guid = null
  description              = each.value.description
  enabled                  = true
  suppression_duration     = "PT5H"
  suppression_enabled      = false
  query_frequency          = "PT5M"
  query_period             = "PT5M"
  trigger_operator         = "GreaterThan"
  trigger_threshold        = 0
}

# Workbook for Cloud Administrator monitoring
resource "azurerm_application_insights_workbook" "cloud_admin_dashboard" {
  count = var.enable_lifecycle_management && var.monitoring_config.enable_monitoring ? 1 : 0
  
  name                = "${var.organization_name}-cloudadmin-dashboard"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  display_name        = "${var.organization_name} Cloud Administrator Dashboard"
  
  data_json = jsonencode({
    version = "Notebook/1.0"
    items = [
      {
        type = 1
        content = {
          json = "# Cloud Administrator Monitoring Dashboard\n\nThis dashboard provides comprehensive monitoring of cloud administrator activities across all tiers."
        }
      },
      {
        type = 12
        content = {
          version = "NotebookGroup/1.0"
          groupType = "editable"
          items = [
            {
              type = 3
              content = {
                version = "KqlItem/1.0"
                query = local.cloud_admin_monitoring_queries.cloud_admin_creation.query
                size = 0
                title = "Recent Cloud Admin Account Creations"
                timeContext = {
                  durationMs = 86400000
                }
                queryType = 0
                resourceType = "microsoft.operationalinsights/workspaces"
              }
            },
            {
              type = 3
              content = {
                version = "KqlItem/1.0"
                query = local.cloud_admin_monitoring_queries.cloud_admin_signin.query
                size = 0
                title = "Cloud Admin Sign-ins"
                timeContext = {
                  durationMs = 86400000
                }
                queryType = 0
                resourceType = "microsoft.operationalinsights/workspaces"
              }
            }
          ]
        }
      }
    ]
  })
  
  tags = {
    Purpose = "Cloud Administrator Monitoring"
    hidden-title = "${var.organization_name} Cloud Admin Dashboard"
  }
}

# Output monitoring configuration
output "monitoring_configuration" {
  description = "Monitoring configuration for cloud administrators"
  value = {
    monitoring_groups = {
      cloud_admin_monitoring = {
        id           = azuread_group.cloud_admin_monitoring.id
        object_id    = azuread_group.cloud_admin_monitoring.object_id
        display_name = azuread_group.cloud_admin_monitoring.display_name
      }
      security_monitoring = {
        id           = azuread_group.security_monitoring_group.id
        object_id    = azuread_group.security_monitoring_group.object_id
        display_name = azuread_group.security_monitoring_group.display_name
      }
    }
    
    kql_queries = local.enhanced_monitoring_queries
    
    log_analytics = var.enable_lifecycle_management && var.automation_account_config.enable_diagnostic_settings ? {
      workspace_id = azurerm_log_analytics_workspace.automation_logs[0].id
      workspace_name = azurerm_log_analytics_workspace.automation_logs[0].name
    } : null
    
    action_groups = var.enable_lifecycle_management && var.monitoring_config.enable_monitoring ? {
      security_alerts = azurerm_monitor_action_group.security_alerts[0].id
    } : null
    
    dashboard = var.enable_lifecycle_management && var.monitoring_config.enable_monitoring ? {
      workbook_id = azurerm_application_insights_workbook.cloud_admin_dashboard[0].id
    } : null
  }
}