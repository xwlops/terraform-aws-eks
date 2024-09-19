## 这是为了对 ECR 进行身份验证，请勿更改它
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubectl" {
  apply_retry_count      = 10
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false
  token                  = data.aws_eks_cluster_auth.this.token
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  # name            = var.project_name
  # cluster_version = "1.30"
  # region          = var.region
  node_group_name = "managed-ondemand"

  node_iam_role_name = module.eks_blueprints_addons.karpenter.node_iam_role_name

  vpc_cidr = "10.0.0.0/16"
  # 创建两个可用区子网
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # tags = {
  #   blueprint = local.name
  # }
}

################################################################################
# Cluster
################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.3"

  cluster_name                   = "${var.project_name}-eks"
  cluster_version                = var.eks_version
  cluster_endpoint_public_access = true

  cluster_addons = {
    kube-proxy = { most_recent = true }
    coredns    = { most_recent = true }

    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  create_cloudwatch_log_group              = false
  create_cluster_security_group            = false
  create_node_security_group               = false
  authentication_mode                      = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    nodes = {
      node_group_name = "managed-ondemand"
      instance_types  = ["t3.large"]
      # instance_types  = ["m4.large", "m5.large", "m5a.large", "m5ad.large", "m5d.large", "t2.large", "t3.large", "t3a.large"]

      create_security_group = false

      subnet_ids   = module.vpc.private_subnets
      max_size     = 2
      desired_size = 1
      min_size     = 1

      # Launch template configuration
      create_launch_template = true              # false will use the default launch template
      launch_template_os     = "amazonlinux2eks" # amazonlinux2eks or bottlerocket

      labels = {
        intent = "control-apps"
      }
    }
  }

  tags = merge(var.tags, {
    # "karpenter.sh/discovery" = "${var.project_name}-eks"
  })
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.3"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # create_delay_dependencies = [for prof in module.eks.eks_managed_node_groups : prof.node_group_arn]

  # enable_aws_load_balancer_controller = true
  # enable_metrics_server               = true

  # enable_karpenter = true

  # karpenter = {
  #   chart_version       = "0.37.0"
  #   repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  #   repository_password = data.aws_ecrpublic_authorization_token.token.password
  # }
  # karpenter_enable_spot_termination          = true
  # karpenter_enable_instance_profile_creation = true
  # karpenter_node = {
  #   iam_role_use_name_prefix = false
  # }

  tags = var.tags
}


module "aws-auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "~> 20.0"

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = module.eks_blueprints_addons.karpenter.node_iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
  ]
}

# ---------------------------------------------------------------
# Supporting Resources
# ---------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.6.0"

  name = "${var.project_name}-vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
    private_subnets = [
    cidrsubnet(local.vpc_cidr, 8, 10), # e.g., 10.0.10.0/24 for AZ1
    cidrsubnet(local.vpc_cidr, 8, 20), # e.g., 10.0.11.0/24 for AZ1
  ]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${var.project_name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${var.project_name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${var.project_name}-default" }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
    "kubernetes.io/role/elb"              = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
    # "karpenter.sh/discovery"              = "${var.project_name}-eks"
  }
  tags = var.tags
}

resource "aws_subnet" "db_private_az_subnet" {
  vpc_id            = module.vpc.vpc_id
  cidr_block        = cidrsubnet(local.vpc_cidr, 8, 11)
  availability_zone = local.azs[0]
  tags = merge(
    {
      Name = "${var.project_name}-private-subnet-db-az"
    },
  )
}

resource "aws_subnet" "db_private_bz_subnet" {
  vpc_id            = module.vpc.vpc_id
  cidr_block        = cidrsubnet(local.vpc_cidr, 8, 21) 
  availability_zone = local.azs[1]
  tags = merge(
    {
      Name = "${var.project_name}-private-subnet-db-bz"
    },
  )
}