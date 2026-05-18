# A random suffix makes the ACR name globally unique (ACR names must be unique
# across all of Azure, like an S3 bucket). Deterministic per state, so it
# doesn't change on every apply.
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

# --- Resource Group ---------------------------------------------------------
# A logical container for everything. Deleting this one group tears the whole
# project down (cost control + clean demos).
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.prefix}"
  location = var.location
}

# --- Azure Container Registry (ACR) ----------------------------------------
# Private registry for the Docker image we built in Phase 2. Basic SKU is the
# cheapest tier and is plenty for this project.
resource "azurerm_container_registry" "acr" {
  name                = "${var.prefix}acr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false # use AAD/managed identity instead of admin user
}

# --- AKS cluster ------------------------------------------------------------
# Managed Kubernetes. The control plane is free on the Free tier; we only pay
# for the single small worker node.
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.prefix
  sku_tier            = "Free"

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.node_vm_size
  }

  # AKS gets its own Azure-managed identity instead of a service principal
  # with a password we'd have to store. Less secret management = more secure.
  identity {
    type = "SystemAssigned"
  }
}

# --- Let AKS pull from ACR without credentials ------------------------------
# Grants the cluster's kubelet identity the built-in "AcrPull" role on the
# registry, so Kubernetes can pull our image with no imagePullSecrets. This is
# the clean, secret-free way to wire ACR -> AKS and a great interview talking
# point.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
