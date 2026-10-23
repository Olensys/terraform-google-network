terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = { source = "hashicorp/google", version = ">= 6.0, < 8.0" }
  }
}

variable "project_id" {
  description = "GCP project that will own the network."
  type        = string
}

locals {
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }
}

module "naming" {
  source = "git::https://github.com/Olensys/terraform-null-naming.git?ref=v1.0.0"

  context = local.context
}

module "this" {
  source = "../../"

  name       = module.naming.name
  context    = local.context
  project_id = var.project_id
  region     = "us-central1"
  labels     = module.naming.labels

  subnets = {
    app = {
      cidr             = "10.10.0.0/20"
      secondary_ranges = { pods = "10.20.0.0/16", services = "10.30.0.0/20" }
    }
    proxy = {
      cidr    = "10.10.16.0/23"
      purpose = "REGIONAL_MANAGED_PROXY"
    }
  }

  enable_nat = true
}

output "network_self_link" {
  description = "Self link of the example network."
  value       = module.this.self_link
}
