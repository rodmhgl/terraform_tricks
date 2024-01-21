provider "azurerm" {
  features {}
}

locals {
  tags = {
    environment = "dev"
    purpose     = "terraform_tips_and_tricks"
  }
}
