# Outputs surface the values we need in later phases (push image, get
# kubeconfig) so we never have to click through the portal.

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "acr_login_server" {
  description = "Use this as the image prefix when tagging/pushing (Phase 2->4)."
  value       = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "get_credentials_command" {
  description = "Run this to point kubectl at the new cluster."
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}
