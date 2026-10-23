# Run only by the nightly integration workflow, against real cloud credentials.
variables {
  project_id = "olensys-integration"
}

run "apply_minimal" {
  command = apply

  module {
    source = "./examples/minimal"
  }
}
