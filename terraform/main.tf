terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      project = var.domain_name
    }
  }
}

provider "aws" {
  // region needs to be us-east-1 for ACM used by CloudFront
  // https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cnames-and-https-requirements.html
  alias  = "acm_provider"
  region = "us-east-1"
  default_tags {
    tags = {
      project = var.domain_name
    }
  }
}

