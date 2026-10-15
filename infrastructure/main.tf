terraform {
  required_version = "~>1.16"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    version = "~>6.0" }
  }
}

provider "aws" {
  region = "ca-central-1"
}