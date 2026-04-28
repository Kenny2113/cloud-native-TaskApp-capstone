terraform {
  backend "s3" {
    bucket         = "taskapp-tf-state-ken-493608842618"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "taskapp-tf-lock"
  }
}