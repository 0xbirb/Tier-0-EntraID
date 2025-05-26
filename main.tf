terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
  
  required_version = ">= 1.0"
}

# Configure the Azure Active Directory Provider
provider "azuread" {
  # Configuration will be provided via environment variables or Azure CLI
}