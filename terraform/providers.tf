# Pins Terraform and provider versions so the project builds the same way on
# any machine / in CI later (Phase 5). Unpinned versions = "works on my
# machine" bugs, which interviewers will ask about.
terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# The azurerm provider authenticates using the Azure CLI session we already
# created with `az login`. azurerm v4 requires the subscription id explicitly.
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
