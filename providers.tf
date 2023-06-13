terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAVQAN5TVLBXYKFMDU"
  secret_key = "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"


}

