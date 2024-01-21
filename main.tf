terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.87.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  tags = {
    environment = "dev"
    purpose     = "terraform_tips_and_tricks"
  }
}
