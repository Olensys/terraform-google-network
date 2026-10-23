output "id" {
  description = "ID of the VPC network. Null when create is false."
  value       = try(local.network.network_id, null)
}

output "name" {
  description = "Name of the VPC network. Null when create is false."
  value       = try(local.network.network_name, null)
}

output "self_link" {
  description = "Self link of the VPC network. Null when create is false."
  value       = try(local.network.network_self_link, null)
}

output "subnet_ids" {
  description = "Map of subnet key to subnet ID. Null when create is false."
  value       = var.create ? { for k in keys(var.subnets) : k => module.this[0].subnets["${var.region}/${k}"].id } : null
}

output "subnet_self_links" {
  description = "Map of subnet key to subnet self link. Null when create is false."
  value       = var.create ? { for k in keys(var.subnets) : k => module.this[0].subnets["${var.region}/${k}"].self_link } : null
}

output "subnet_names" {
  description = "Map of subnet key to subnet name. Null when create is false."
  value       = var.create ? { for k in keys(var.subnets) : k => module.this[0].subnets["${var.region}/${k}"].name } : null
}

output "nat_ips" {
  description = "External addresses used by Cloud NAT. Empty when NAT is disabled; null when create is false."
  value       = var.create ? google_compute_address.nat[*].address : null
}

output "nat_enabled" {
  description = "Whether Cloud NAT is created. Null when create is false."
  value       = var.create ? var.enable_nat : null
}

output "vpc_connector_id" {
  description = "ID of the Serverless VPC Access connector. Null when there is no connector or create is false."
  value       = try(google_vpc_access_connector.this[0].id, null)
}

output "private_service_access_range" {
  description = "Name of the reserved private service access range. Null when private service access is not configured or create is false."
  value       = try(google_compute_global_address.psa[0].name, null)
}

output "subnet_config" {
  description = "Subnet list passed to the upstream network module."
  value       = var.create ? local.subnet_config : null
}

output "labels" {
  description = "Labels applied to every labelable resource, with context.extra_tags merged in. Null when create is false."
  value       = var.create ? local.labels : null
}
