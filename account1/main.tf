terraform {
  backend "s3" {
    # Create the bucket first before executing.
    # Being unique, this assures that scripts in each project folder do not overlap or overwrite each other.
    bucket = "account1"
    # You can choose a subfolder if you want.
    # key    = "/"
    region = "ap-southeast-1"

  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.19.0"
    }
  }

  required_version = ">= 1.5.7"
}

provider "aws" {
  region = "ap-southeast-1"
  # Profile should be set in environment variable AWS_PROFILE
}
