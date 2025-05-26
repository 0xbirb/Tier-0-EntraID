terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
  
  required_version = ">= 1.0"
}

# Configure the Azure Active Directory Provider using Service Principal
provider "azuread" {
  client_id     = var.client_id
  client_secret = var.client_secret  
  tenant_id     = var.tenant_id
}