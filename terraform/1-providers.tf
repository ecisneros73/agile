provider "aws" {
  region = var.region
}

provider "github" {
  owner = "ecisneros74@gmail.com"
}

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49"
    }

    github = {
      source = "integrations/github"
    }
  }
  backend "s3" {
    bucket       = "terraform-delete-test"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
  
}
