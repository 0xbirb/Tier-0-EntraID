# High-risk Graph API permissions that should be monitored
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

# Monitoring queries for security operations
locals {
  monitoring_queries = {
    dangerous_app_permissions = jsonencode({
      query = "AuditLogs | where OperationName == 'Add app role assignment to service principal' | where Result =~ 'success' | mv-expand TargetResources | mv-expand TargetResources.modifiedProperties | where TargetResources_modifiedProperties.displayName == 'AppRole.Value' | extend AddedPermission = replace_string(tostring(TargetResources_modifiedProperties.newValue),'\"','') | where AddedPermission in~ ('RoleManagement.ReadWrite.Directory', 'Application.ReadWrite.All', 'AppRoleAssignment.ReadWrite.All')"
      description = "Monitor assignments of dangerous Graph API permissions"
    })
    
    service_principal_credential_creation = jsonencode({
      query = "AuditLogs | where OperationName == 'Add service principal credentials' | where InitiatedBy.user.userPrincipalName != '' | project TimeGenerated, OperationName, InitiatedBy.user.userPrincipalName, TargetResources[0].displayName"
      description = "Monitor creation of service principal credentials by users"
    })
    
    privileged_role_assignments = jsonencode({
      query = "AuditLogs | where OperationName == 'Add member to role' | where TargetResources[0].modifiedProperties | extend RoleName = tostring(TargetResources[0].modifiedProperties[1].newValue) | where RoleName in ('Global Administrator', 'Privileged Role Administrator', 'Application Administrator')"
      description = "Monitor assignments to high-privilege roles"
    })
    
    azure_elevation_access = jsonencode({
      query = "AzureActivity | where OperationNameValue =~ 'Microsoft.Authorization/elevateAccess/action' | extend timestamp = TimeGenerated, AccountCustomEntity = Caller, IPCustomEntity = CallerIpAddress"
      description = "Monitor Global Admin elevation to Azure subscriptions"
    })
    
    vm_run_command_abuse = jsonencode({
      query = "AzureActivity | where CategoryValue == 'Administrative' | where OperationNameValue =~ 'Microsoft.Compute/virtualMachines/runCommand/action' | extend VMName = tostring(todynamic(Properties).resource) | summarize make_list(ActivityStatusValue), TimeGenerated = max(TimeGenerated) by CorrelationId, CallerIpAddress, Caller, ResourceGroup, VMName"
      description = "Monitor VM RunCommand operations for lateral movement"
    })
  }
  
  emergency_procedures = {
    break_glass_activation = {
      step1 = "Verify emergency situation with at least two senior stakeholders"
      step2 = "Enable break-glass account: Get-AzureADUser -ObjectId <break-glass-id> | Set-AzureADUser -AccountEnabled $true"
      step3 = "Document emergency access in incident log"
      step4 = "Monitor break-glass account activity continuously during emergency"
      step5 = "Disable break-glass account immediately after emergency: Set-AzureADUser -AccountEnabled $false"
      step6 = "Reset break-glass password and review access logs"
      step7 = "Update emergency procedures based on lessons learned"
    }
    
    compromise_response = {
      step1 = "Immediately disable suspected compromised accounts"
      step2 = "Review all role assignments made by compromised account"
      step3 = "Check for new application registrations and credentials"
      step4 = "Review Azure Activity logs for elevation activities"
      step5 = "Scan for VM RunCommand operations from compromised accounts"
      step6 = "Reset credentials for all potentially affected service principals"
      step7 = "Review and revoke all dangerous Graph API permissions"
    }
  }
}