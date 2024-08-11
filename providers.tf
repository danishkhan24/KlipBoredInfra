terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use a consistent version across your modules
    }
  }

  required_version = ">= 1.0"
}

provider "aws" {
  region = var.region
}
