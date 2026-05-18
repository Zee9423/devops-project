# Remote state backend.
#
# Terraform state records what infrastructure exists. Storing it remotely in
# Azure Blob Storage (instead of a local terraform.tfstate file) means:
#   - state survives losing this machine
#   - CI and teammates share one source of truth
#   - the blob's lease provides STATE LOCKING, so two applies can't run at
#     once and corrupt state
#
# This storage account was created out-of-band with the Azure CLI (the
# "bootstrap" step) because the backend must exist before Terraform can use
# it. Backend blocks can't use variables, so values are literal — none of
# these are secrets; access is controlled by Azure RBAC.
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-fastapiaks"
    storage_account_name = "tfstatefastapiaks26273"
    container_name       = "tfstate"
    key                  = "fastapi-aks.tfstate"
  }
}
