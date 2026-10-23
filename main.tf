locals {
  extra_labels = { for k, v in var.context.extra_tags :
  substr(replace(lower(k), "/[^a-z0-9_-]/", "-"), 0, 63) => substr(replace(lower(v), "/[^a-z0-9_-]/", "-"), 0, 63) }
  labels = merge(local.extra_labels, var.labels)

  # Proxy-only and Private Service Connect subnets do not support flow logs.
  subnet_config = [
    for name, s in var.subnets : merge(
      {
        subnet_name           = name
        subnet_ip             = s.cidr
        subnet_region         = var.region
        subnet_private_access = tostring(s.purpose == null ? s.private_google_access : false)
        subnet_flow_logs      = tostring(s.purpose == null)
      },
      s.purpose == null ? { subnet_flow_logs_sampling = "0.5" } : {},
      s.purpose == null ? {} : { purpose = s.purpose },
      s.purpose == "REGIONAL_MANAGED_PROXY" ? { role = "ACTIVE" } : {},
    )
  ]

  secondary_ranges = {
    for name, s in var.subnets : name => [
      for range_name, cidr in s.secondary_ranges : { range_name = range_name, ip_cidr_range = cidr }
    ] if length(s.secondary_ranges) > 0
  }

  network = var.create ? module.this[0] : null

  # Connector names are limited to 25 characters.
  connector_name = "${trimsuffix(substr(var.name, 0, 20), "-")}-conn"
}

module "this" {
  source  = "terraform-google-modules/network/google"
  version = "18.3.1"

  count = var.create ? 1 : 0

  project_id   = var.project_id
  network_name = var.name
  routing_mode = "REGIONAL"

  delete_default_internet_gateway_routes = false

  subnets          = local.subnet_config
  secondary_ranges = local.secondary_ranges

  firewall_rules = [
    for r in var.firewall_rules : {
      name        = r.name
      direction   = r.direction
      ranges      = r.ranges
      allow       = r.allow
      target_tags = r.target_tags
    }
  ]
}

resource "google_compute_address" "nat" {
  count = var.create && var.enable_nat ? 1 : 0

  project      = var.project_id
  name         = "${var.name}-nat"
  region       = var.region
  address_type = "EXTERNAL"
  labels       = local.labels
}

module "nat" {
  source  = "terraform-google-modules/cloud-nat/google"
  version = "7.1.0"

  count = var.create && var.enable_nat ? 1 : 0

  project_id    = var.project_id
  name          = "${var.name}-nat"
  create_router = true
  router        = "${var.name}-router"
  network       = module.this[0].network_name
  region        = var.region
  nat_ips       = [google_compute_address.nat[0].self_link]

  log_config_enable = true
  log_config_filter = "ERRORS_ONLY"
}

resource "google_compute_global_address" "psa" {
  count = var.create && var.private_service_access_cidr != null ? 1 : 0

  project       = var.project_id
  name          = "${var.name}-psa"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = cidrhost(var.private_service_access_cidr, 0)
  prefix_length = tonumber(split("/", var.private_service_access_cidr)[1])
  network       = module.this[0].network_self_link
  labels        = local.labels
}

resource "google_service_networking_connection" "psa" {
  count = var.create && var.private_service_access_cidr != null ? 1 : 0

  network                 = module.this[0].network_self_link
  deletion_policy         = "ABANDON"
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa[0].name]
}

resource "google_vpc_access_connector" "this" {
  count = var.create && var.vpc_connector != null ? 1 : 0

  project        = var.project_id
  name           = local.connector_name
  region         = var.region
  network        = module.this[0].network_name
  ip_cidr_range  = var.vpc_connector.cidr
  min_throughput = var.vpc_connector.min_throughput
  max_throughput = var.vpc_connector.max_throughput
}
