# Inputs are variables (not hardcoded) so the same code can target different
# subscriptions/regions/sizes — exactly what you'd do for dev vs prod.

variable "subscription_id" {
  description = "Azure subscription ID to deploy into."
  type        = string
  default     = "3e71f502-e5cd-4260-ba04-2d8d3cfda535"
}

variable "prefix" {
  description = "Short name prefixed to every resource for easy identification."
  type        = string
  default     = "fastapiaks"
}

variable "location" {
  description = "Azure region. West Europe is close to Egypt and supports AKS."
  type        = string
  default     = "westeurope"
}

variable "node_count" {
  description = "Number of nodes in the AKS default pool. 1 keeps cost minimal."
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "VM size for AKS nodes. Standard_B2s_v2 is a cheap burstable size allowed on free subscriptions (the older Standard_B2s is restricted in some regions)."
  type        = string
  default     = "Standard_B2s_v2"
}
