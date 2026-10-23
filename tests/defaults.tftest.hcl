mock_provider "google-beta" {}

mock_provider "random" {}

mock_provider "google" {}

variables {
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }
  name       = "example"
  project_id = "example-project"
  region     = "us-central1"
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
}

run "test_nat_default_on" {
  command = plan

  assert {
    condition     = output.nat_enabled == true && length(google_compute_address.nat) == 1
    error_message = "NAT must default to enabled and reserve one address."
  }
}

run "test_nat_disabled" {
  command = plan

  variables {
    enable_nat = false
  }

  assert {
    condition     = length(google_compute_address.nat) == 0 && output.nat_ips == []
    error_message = "No NAT address and no nat_ips when NAT is disabled."
  }
}

run "test_secondary_ranges_mapped" {
  command = plan

  assert {
    condition     = length(output.secondary_ranges["app"]) == 2 && !contains(keys(output.secondary_ranges), "proxy")
    error_message = "Secondary ranges are mapped per subnet, only for subnets that define them."
  }

  assert {
    condition     = [for r in output.secondary_ranges["app"] : r if r.range_name == "pods"][0].ip_cidr_range == "10.20.0.0/16"
    error_message = "Range name and CIDR must be passed through."
  }
}

run "test_subnet_outputs_keyed_by_input" {
  command = plan

  assert {
    condition     = toset(keys(output.subnet_names)) == toset(["app", "proxy"]) && toset(keys(output.subnet_self_links)) == toset(["app", "proxy"]) && toset(keys(output.subnet_ids)) == toset(["app", "proxy"])
    error_message = "Subnet output maps must be keyed by the input subnet key."
  }
}

run "test_subnets_from_map" {
  command = plan

  assert {
    condition     = length(output.subnet_config) == 2
    error_message = "One upstream subnet entry per map entry."
  }

  assert {
    condition     = [for s in output.subnet_config : s if s.subnet_name == "app"][0].subnet_ip == "10.10.0.0/20"
    error_message = "app subnet cidr must be passed through."
  }

  assert {
    condition     = [for s in output.subnet_config : s if s.subnet_name == "app"][0].subnet_private_access == "true"
    error_message = "Private Google access defaults to true."
  }
}

run "test_proxy_only_purpose" {
  command = plan

  assert {
    condition = (
      [for s in output.subnet_config : s if s.subnet_name == "proxy"][0].purpose == "REGIONAL_MANAGED_PROXY"
      && [for s in output.subnet_config : s if s.subnet_name == "proxy"][0].role == "ACTIVE"
      && [for s in output.subnet_config : s if s.subnet_name == "proxy"][0].subnet_flow_logs == "false"
    )
    error_message = "Proxy-only subnet needs purpose, role ACTIVE and no flow logs."
  }
}

run "test_psa_created_when_cidr" {
  command = plan

  variables {
    private_service_access_cidr = "10.40.0.0/16"
  }

  assert {
    condition     = google_compute_global_address.psa[0].prefix_length == 16
    error_message = "prefix_length must come from the CIDR."
  }

  assert {
    condition     = output.private_service_access_range == "example-psa"
    error_message = "PSA range name must be exposed."
  }
}

run "test_flow_logs_on" {
  command = plan

  assert {
    condition     = [for s in output.subnet_config : s if s.subnet_name == "app"][0].subnet_flow_logs == "true" && [for s in output.subnet_config : s if s.subnet_name == "app"][0].subnet_flow_logs_sampling == "0.5"
    error_message = "Flow logs must be on at 0.5 sampling for ordinary subnets."
  }
}

run "test_vpc_connector_created" {
  command = plan

  variables {
    vpc_connector = { cidr = "10.50.0.0/28" }
  }

  assert {
    condition     = google_vpc_access_connector.this[0].min_throughput == 200 && google_vpc_access_connector.this[0].max_throughput == 300
    error_message = "Connector throughput defaults must be 200/300."
  }
}

run "test_vpc_connector_throughput_validation" {
  command = plan

  variables {
    vpc_connector = { cidr = "10.50.0.0/28", min_throughput = 250 }
  }

  expect_failures = [var.vpc_connector]
}

run "test_name_must_start_with_letter" {
  command = plan

  variables {
    name = "1bad"
  }

  expect_failures = [var.name]
}

run "test_create_false_plans_nothing" {
  command = plan

  variables {
    create = false
  }

  assert {
    condition = alltrue([
      output.id == null, output.name == null, output.self_link == null,
      output.subnet_ids == null, output.subnet_self_links == null, output.subnet_names == null,
      output.nat_ips == null, output.vpc_connector_id == null,
      output.private_service_access_range == null, output.labels == null,
    ])
    error_message = "Every output must be null when create is false."
  }
}

run "test_name_length_validation" {
  command = plan

  variables {
    name = "a1234567890123456789012345678901234567890123456789012345678901234"
  }

  expect_failures = [var.name]
}

run "test_tags_contract" {
  command = plan

  variables {
    labels = { owner = "x" }
    context = {
      organization = "olensys"
      environment  = "test"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
      extra_tags   = { owner = "y", team = "z" }
    }
  }

  assert {
    condition     = output.labels.owner == "x"
    error_message = "var.labels must win over context.extra_tags."
  }

  assert {
    condition     = output.labels.team == "z"
    error_message = "context.extra_tags must be merged."
  }
}
