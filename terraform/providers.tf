terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    pinecone = {
      source  = "pinecone-io/pinecone"
      version = "~> 2.0.0"
    }
    openai = {
      source  = "jianyuan/openai"
      version = "~> 0.4.0" # Check for the latest version on Terraform Registry
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "pinecone" {
  api_key = var.pinecone_api_key
}

provider "openai" {
  api_key = var.openai_api_key
}