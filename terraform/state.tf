terraform {
  backend "s3" {
    bucket = "itsre-state-783633885093"
    key    = "us-west-2/itse-apps-admin-1/terraform.tfstate"
    region = "eu-west-1"
  }
}
