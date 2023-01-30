terraform {
  required_version = ">= 1.2.2"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [
        aws.region,
        aws.global,
        aws.management,
      ]
    }
  }
}

data "aws_region" "current" {
  provider = aws.region
}

data "aws_caller_identity" "current" {
  provider = aws.region
}

data "aws_default_tags" "current" {
  provider = aws.region
}

data "aws_caller_identity" "global" {
  provider = aws.global
}

data "aws_region" "global" {
  provider = aws.global
}

data "aws_caller_identity" "management" {
  provider = aws.management
}

data "aws_region" "management" {
  provider = aws.management
}
