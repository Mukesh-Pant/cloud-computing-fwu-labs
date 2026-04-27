terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
  default_tags {
    tags = {
      Owner   = "Mukesh"
      Project = "FWU-CloudComputing-Lab"
      Lab     = var.lab_name
    }
  }
}
