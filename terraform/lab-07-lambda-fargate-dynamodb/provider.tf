terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Owner   = var.display_name
      Project = "FWU-CloudComputing-Lab"
      Lab     = var.lab_name
    }
  }
}
