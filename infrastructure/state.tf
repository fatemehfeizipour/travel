terraform {
  backend "s3" {
    bucket       = "travelease-contact-form-state"
    key          = "travelease/terraform.tfstate"
    region       = "ca-central-1"
    encrypt      = true
    use_lockfile = true

  }
}

