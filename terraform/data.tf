
data "terraform_remote_state" "deploy" {
  backend = "s3"

  config = {
    bucket = "itsre-state-783633885093"
    key    = "terraform/deploy.tfstate"
    region = "eu-west-1"
  }
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "this" {
  id = data.terraform_remote_state.deploy.outputs.vpc_id
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
