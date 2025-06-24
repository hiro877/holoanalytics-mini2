terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.50" }
  }
}
provider "aws" {
  region = var.aws_region #どのリージョンに作るかを 変数 aws_region（variables.tf で定義）で指定。例: "ap-northeast-1"
  default_tags {
    tags = { Project = "HoloAnalytics-Mini", Owner = "tatto", Env = var.env }
  }
}

