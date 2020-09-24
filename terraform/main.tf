provider "aws" {
  region = var.region
}

locals {
  cluster_name = "itse-apps-admin-1"

  cluster_features = {
    "prometheus"         = true
    "flux"               = true
    "flux_helm_operator" = true
    "aws_calico"         = true
    "external_secrets"   = true
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

  flux_settings = {
    "git.url"    = "git@github.com:mozilla-it/itse-apps-admin-1-infra"
    "git.path"   = "k8s"
    "git.branch" = "main"
  }

  prometheus_scrape_config = <<EOF
- job_name: 'federation-stage-2'
  scrape_interval: 15s
  metrics_path: /
  basic_auth:
    password_file: '/secrets/auth.txt'
  static_configs:
    - targets:
        - 'prom.itse-apps-stage-2.k8s.mozit.cloud:9090'
EOF

  prometheus_mount_config = <<EOF
- name: prometheus-creds
  mountPath: /secrets
  secretName: prometheus-creds
EOF

  prometheus_settings = { "extraScrapeConfigs" = local.prometheus_scrape_config, "extraSecretMounts" = local.prometheus_mount_config }
}

module "eks" {
  source              = "github.com/mozilla-it/terraform-modules//aws/eks?ref=master"
  cluster_name        = local.cluster_name
  cluster_version     = "1.17"
  vpc_id              = data.terraform_remote_state.deploy.outputs.vpc_id
  cluster_subnets     = data.terraform_remote_state.deploy.outputs.public_subnets
  cluster_features    = local.cluster_features
  flux_settings       = local.flux_settings
  node_groups         = local.node_groups
  admin_users_arn     = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/maws-admin"]
  prometheus_settings = local.prometheus_settings
}
