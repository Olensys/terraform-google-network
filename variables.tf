variable "name" {
  description = "Resource name. Lowercase letters, digits and hyphens."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{1,63}$", var.name))
    error_message = "name must match ^[a-z0-9-]{1,63}$."
  }
}

variable "context" {
  description = "Deployment context used for naming, tagging and environment-dependent defaults."
  type = object({
    organization = string
    environment  = string
    application  = string
    component    = optional(string)
    owner        = string
    cost_center  = string
    extra_tags   = optional(map(string), {})
  })
  validation {
    condition     = contains(["dev", "staging", "prod", "test", "shared"], var.context.environment)
    error_message = "context.environment must be one of dev, staging, prod, test, shared."
  }
}

variable "project_id" {
  description = "ID of the GCP project that owns the network."
  type        = string
}

variable "create" {
  description = "Whether to create any resources. Set false to create nothing."
  type        = bool
  default     = true
}


variable "region" {
  description = "Region for every subnet, the Cloud Router and the VPC connector."
  type        = string
}

variable "subnets" {
  description = "Subnets keyed by name. secondary_ranges maps range name to CIDR. purpose is null, REGIONAL_MANAGED_PROXY or PRIVATE_SERVICE_CONNECT; flow logs are enabled on every subnet that supports them."
  type = map(object({
    cidr                  = string
    secondary_ranges      = optional(map(string), {})
    private_google_access = optional(bool, true)
    purpose               = optional(string)
  }))
  default = {}
  validation {
    condition     = alltrue([for s in values(var.subnets) : can(cidrhost(s.cidr, 0))])
    error_message = "Every subnet cidr must be a valid CIDR block."
  }
  validation {
    condition     = alltrue([for s in values(var.subnets) : s.purpose == null || contains(["REGIONAL_MANAGED_PROXY", "PRIVATE_SERVICE_CONNECT"], coalesce(s.purpose, "-"))])
    error_message = "Subnet purpose must be null, REGIONAL_MANAGED_PROXY or PRIVATE_SERVICE_CONNECT."
  }
}

variable "enable_nat" {
  description = "Create a Cloud Router and a Cloud NAT with a reserved external address."
  type        = bool
  default     = true
}

variable "private_service_access_cidr" {
  description = "CIDR reserved for private service access (Cloud SQL, Memorystore). Null disables it."
  type        = string
  default     = null
  validation {
    condition     = var.private_service_access_cidr == null || can(cidrhost(coalesce(var.private_service_access_cidr, "0.0.0.0/0"), 0))
    error_message = "private_service_access_cidr must be a valid CIDR block."
  }
}

variable "vpc_connector" {
  description = "Serverless VPC Access connector. cidr must be an unused /28. Null disables it."
  type = object({
    cidr           = string
    min_throughput = optional(number, 200)
    max_throughput = optional(number, 300)
  })
  default = null
  validation {
    condition     = var.vpc_connector == null || can(cidrhost(try(var.vpc_connector.cidr, "0.0.0.0/0"), 0))
    error_message = "vpc_connector.cidr must be a valid CIDR block."
  }
  validation {
    condition     = var.vpc_connector == null || try(var.vpc_connector.min_throughput < var.vpc_connector.max_throughput, false)
    error_message = "vpc_connector.min_throughput must be lower than max_throughput."
  }
}

variable "firewall_rules" {
  description = "Firewall rules. No default-allow rule is created."
  type = list(object({
    name      = string
    direction = optional(string, "INGRESS")
    ranges    = list(string)
    allow = list(object({
      protocol = string
      ports    = optional(list(string))
    }))
    target_tags = optional(list(string))
  }))
  default = []
  validation {
    condition     = alltrue([for r in var.firewall_rules : contains(["INGRESS", "EGRESS"], r.direction)])
    error_message = "Firewall rule direction must be INGRESS or EGRESS."
  }
}

variable "labels" {
  description = "Labels merged onto every labelable resource, applied last. Must already be valid GCP labels."
  type        = map(string)
  default     = {}
}
