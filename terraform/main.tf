provider "aws" {
  region = var.region
}

locals {
  cluster_name = "itse-apps-admin-1"

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

  roles = [
    {
      username = "maws-admin"
      rolearn  = "arn:aws:iam::783633885093:role/maws-admin"
      groups   = ["system:masters"]
    },
  ]
}

module "eks" {
  source          = "github.com/mozilla-it/terraform-modules//aws/eks?ref=master"
  cluster_name    = local.cluster_name
  cluster_version = "1.17"
  vpc_id          = data.terraform_remote_state.deploy.outputs.vpc_id
  cluster_subnets = data.terraform_remote_state.deploy.outputs.public_subnets
  map_roles       = local.roles
  node_groups     = local.node_groups
}
