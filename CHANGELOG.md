# Changelog

## [1.1.1](https://github.com/Olensys/terraform-google-network/compare/v1.1.0...v1.1.1) (2026-10-24)


### Bug Fixes

* **examples:** pin naming module to v1.0.1 ([0ce8fe2](https://github.com/Olensys/terraform-google-network/commit/0ce8fe238065a193658a693cc9a8fedad2cadb1b))
* run integration on change and weekly instead of nightly ([5315917](https://github.com/Olensys/terraform-google-network/commit/53159172508ac719c9e79a6013e5db45bc86bc6d))

## 1.1.0

### Fixes

- normalise `context.extra_tags` keys and values to valid GCP label syntax (lowercase, `[^a-z0-9_-]` replaced by `-`, 63 characters); `labels` are applied verbatim and win
- bound `random` to `>= 3.5, < 4.0`

### Tests

- `test_tags_contract` now covers mixed-case extra tags and verifies normalisation

### Docs

- Usage shows the naming module; Opinions describe label normalisation

### Behaviour changes

- `labels` output and applied labels now contain normalised keys and values for `context.extra_tags` (for example `Team = "Core Team"` becomes `team = "core-team"`). Callers that relied on mixed-case or space-containing extra tags must expect the normalised form; values passed in `labels` are unchanged.

## 1.0.1

### Fixes

- state the upstream google provider minimum
- declare and mock google-beta required by the upstream module
- validate connector throughput and name shape, abandon PSA peering on destroy, strengthen NAT tests

## 1.0.0

- VPC network with subnets from a map, flow logs, Cloud NAT, private service access and an optional Serverless VPC Access connector, wrapping terraform-google-modules/network/google 18.3.1 and terraform-google-modules/cloud-nat/google 7.1.0.
