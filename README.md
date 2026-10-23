# terraform-google-network

VPC network with subnets, flow logs, Cloud NAT, private service access and an optional Serverless VPC Access connector

## Opinions

- Regional routing mode; the default internet gateway routes are kept.
- Flow logs on every subnet that supports them, sampling 0.5. Proxy-only and Private Service Connect subnets get none, and proxy-only subnets use role `ACTIVE`.
- Cloud NAT on by default, with a reserved external address and `ERRORS_ONLY` logging; the Cloud Router is named `<name>-router`.
- No default-allow firewall rule is created.
- Private service access (`<name>-psa` range plus the service networking connection) and the Serverless VPC Access connector are off until their inputs are set. Connector names are truncated to fit the 25 character limit.
- `name` starts with a letter, does not end with a hyphen and is at most 56 characters so derived names (`<name>-router`, `<name>-psa`) fit the 63 character limit.
- The service networking connection uses `deletion_policy = "ABANDON"`: destroying this module leaves the peering in place so Cloud SQL and Memorystore instances keep using the range.
- VPC connector throughput must be 200 to 1000 in steps of 100.
- `labels` are applied to the reserved addresses only: the network, subnets, router and connector do not accept labels. Labels must already be valid GCP labels; they are not transformed.

## Requirements note

The pinned upstream module requires `google` >= 6.28 (subnets submodule), `google-beta` >= 6.19 and `random` ~> 3.0, so this module declares those minimums instead of the library-wide floor.

## Usage

```hcl
module "this" {
  source = "git::https://github.com/Olensys/terraform-google-network.git?ref=v1.0.0"

  name       = "example"
  project_id = "my-project"
  region     = "us-central1"
  subnets    = { app = { cidr = "10.10.0.0/20" } }
  context = {
    organization = "olensys"
    environment  = "dev"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.28, < 8.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 6.19, < 8.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.28, < 8.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_nat"></a> [nat](#module\_nat) | terraform-google-modules/cloud-nat/google | 7.1.0 |
| <a name="module_this"></a> [this](#module\_this) | terraform-google-modules/network/google | 18.3.1 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_compute_address.nat](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_global_address.psa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_service_networking_connection.psa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_networking_connection) | resource |
| [google_vpc_access_connector.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/vpc_access_connector) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_context"></a> [context](#input\_context) | Deployment context used for naming, tagging and environment-dependent defaults. | <pre>object({<br/>    organization = string<br/>    environment  = string<br/>    application  = string<br/>    component    = optional(string)<br/>    owner        = string<br/>    cost_center  = string<br/>    extra_tags   = optional(map(string), {})<br/>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Network name. Lowercase letters, digits and hyphens; starts with a letter, does not end with a hyphen, at most 56 characters so derived names such as <name>-router fit the 63 character limit. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | ID of the GCP project that owns the network. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region for every subnet, the Cloud Router and the VPC connector. | `string` | n/a | yes |
| <a name="input_create"></a> [create](#input\_create) | Whether to create any resources. Set false to create nothing. | `bool` | `true` | no |
| <a name="input_enable_nat"></a> [enable\_nat](#input\_enable\_nat) | Create a Cloud Router and a Cloud NAT with a reserved external address. | `bool` | `true` | no |
| <a name="input_firewall_rules"></a> [firewall\_rules](#input\_firewall\_rules) | Firewall rules. No default-allow rule is created. | <pre>list(object({<br/>    name      = string<br/>    direction = optional(string, "INGRESS")<br/>    ranges    = list(string)<br/>    allow = list(object({<br/>      protocol = string<br/>      ports    = optional(list(string))<br/>    }))<br/>    target_tags = optional(list(string))<br/>  }))</pre> | `[]` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels merged onto every labelable resource, applied last. Must already be valid GCP labels. | `map(string)` | `{}` | no |
| <a name="input_private_service_access_cidr"></a> [private\_service\_access\_cidr](#input\_private\_service\_access\_cidr) | CIDR reserved for private service access (Cloud SQL, Memorystore). Null disables it. | `string` | `null` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Subnets keyed by name. secondary\_ranges maps range name to CIDR. purpose is null, REGIONAL\_MANAGED\_PROXY or PRIVATE\_SERVICE\_CONNECT; flow logs are enabled on every subnet that supports them. | <pre>map(object({<br/>    cidr                  = string<br/>    secondary_ranges      = optional(map(string), {})<br/>    private_google_access = optional(bool, true)<br/>    purpose               = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_vpc_connector"></a> [vpc\_connector](#input\_vpc\_connector) | Serverless VPC Access connector. cidr must be an unused /28. Null disables it. | <pre>object({<br/>    cidr           = string<br/>    min_throughput = optional(number, 200)<br/>    max_throughput = optional(number, 300)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | ID of the VPC network. Null when create is false. |
| <a name="output_labels"></a> [labels](#output\_labels) | Labels applied to every labelable resource, with context.extra\_tags merged in. Null when create is false. |
| <a name="output_name"></a> [name](#output\_name) | Name of the VPC network. Null when create is false. |
| <a name="output_nat_enabled"></a> [nat\_enabled](#output\_nat\_enabled) | Whether Cloud NAT is created. Null when create is false. |
| <a name="output_nat_ips"></a> [nat\_ips](#output\_nat\_ips) | External addresses used by Cloud NAT. Empty when NAT is disabled; null when create is false. |
| <a name="output_private_service_access_range"></a> [private\_service\_access\_range](#output\_private\_service\_access\_range) | Name of the reserved private service access range. Null when private service access is not configured or create is false. |
| <a name="output_secondary_ranges"></a> [secondary\_ranges](#output\_secondary\_ranges) | Secondary ranges passed to the upstream network module, keyed by subnet. Null when create is false. |
| <a name="output_self_link"></a> [self\_link](#output\_self\_link) | Self link of the VPC network. Null when create is false. |
| <a name="output_subnet_config"></a> [subnet\_config](#output\_subnet\_config) | Subnet list passed to the upstream network module. |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | Map of subnet key to subnet ID. Null when create is false. |
| <a name="output_subnet_names"></a> [subnet\_names](#output\_subnet\_names) | Map of subnet key to subnet name. Null when create is false. |
| <a name="output_subnet_self_links"></a> [subnet\_self\_links](#output\_subnet\_self\_links) | Map of subnet key to subnet self link. Null when create is false. |
| <a name="output_vpc_connector_id"></a> [vpc\_connector\_id](#output\_vpc\_connector\_id) | ID of the Serverless VPC Access connector. Null when there is no connector or create is false. |
<!-- END_TF_DOCS -->
