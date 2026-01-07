provider "aws" {
  region = var.AWS_REGION

  default_tags {
    tags = {
      Environment = "Dev"
      Service     = "EKS-Cluster"
    }
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.EKS_CLUSTER_NAME}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.AWS_REGION}a", "${var.AWS_REGION}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.EKS_CLUSTER_NAME
  cluster_version = "1.29"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  # Оптимізація дисків та вузлів
  eks_managed_node_groups = {
    nodes = {
      min_size       = 1
      max_size       = 5
      desired_size   = var.EKS_NUM_NODES
      instance_types = [var.EKS_INSTANCE_TYPE]

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            delete_on_termination = true
          }
        }
      }
    }
  }
}

# --- Провайдери для FluxCD та GitHub ---
provider "github" {
  owner = var.GITHUB_OWNER
  token = var.GITHUB_TOKEN
}

# Отримуємо токен автентифікації для підключення до EKS
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# 1. Генерація TLS ключів (SSH) для зв'язку Flux та GitHub
module "tls_keys" {
  source = "github.com/den-vasyliev/tf-hashicorp-tls-keys"
}

# 2. Створення GitOps репозиторію на GitHub
module "github_repository" {
  source                   = "github.com/den-vasyliev/tf-github-repository"
  github_owner             = var.GITHUB_OWNER
  github_token             = var.GITHUB_TOKEN
  repository_name          = "kbot-gitops"
  public_key_openssh       = module.tls_keys.public_key_openssh
  public_key_openssh_title = "flux-ssh-key"
}

# 3. Встановлення (Bootstrap) FluxCD у ваш EKS кластер
module "flux_bootstrap" {
  source            = "github.com/den-vasyliev/tf-fluxcd-flux-bootstrap"
  github_repository = "${var.GITHUB_OWNER}/${module.github_repository.repository_name}"
  private_key_pem   = module.tls_keys.private_key_pem
  config_path       = "~/.kube/config"
}