terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.92"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~>2.8"
    }
  }
  required_version = ">= 1.2"
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
