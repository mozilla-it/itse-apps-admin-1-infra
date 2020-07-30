provider "aws" {
  region = var.region
}

locals {
  cluster_name = "itse-apps-admin-1"

  cluster_features = {
    "aws_calico" = true
  }

  node_groups = {
    default-nodegroup = {
      desired_capacity = "3"
      min_capacity     = "3"
      max_capacity     = "20"
      instance_type    = "m5.large"
      disk_size        = "100"
      subnets          = data.terraform_remote_state.deploy.outputs.private_subnets

      k8s_labels = {
        Node = "managed"
      }

      additional_tags = {
        "kubernetes.io/cluster/${local.cluster_name}" = "owned"
        "k8s.io/cluster-autoscaler/enabled"           = "true"
      }
    }
  }
}

module "eks" {
  source           = "github.com/mozilla-it/terraform-modules//aws/eks?ref=master"
  cluster_name     = local.cluster_name
  cluster_version  = "1.17"
  vpc_id           = data.terraform_remote_state.deploy.outputs.vpc_id
  cluster_subnets  = data.terraform_remote_state.deploy.outputs.public_subnets
  cluster_features = local.cluster_features
  node_groups      = local.node_groups
  admin_users_arn  = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/maws-admin"]
}
