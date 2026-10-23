# Changelog

## 1.0.1

### Fixes

- state the upstream google provider minimum
- declare and mock google-beta required by the upstream module
- validate connector throughput and name shape, abandon PSA peering on destroy, strengthen NAT tests

## 1.0.0

- VPC network with subnets from a map, flow logs, Cloud NAT, private service access and an optional Serverless VPC Access connector, wrapping terraform-google-modules/network/google 18.3.1 and terraform-google-modules/cloud-nat/google 7.1.0.
