# --- AWS Variables ---

variable "AWS_REGION" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for EKS and VPC"
}

variable "EKS_CLUSTER_NAME" {
  type        = string
  default     = "my-eks-cluster"
  description = "Name of the EKS cluster"
}

variable "EKS_NUM_NODES" {
  type        = number
  default     = 2
  description = "Desired number of worker nodes"
}

variable "EKS_INSTANCE_TYPE" {
  type        = string
  default     = "t3.medium"
  description = "Instance type for EKS nodes"
}

# --- GitHub Variables (потрібні для Flux завдання) ---

variable "GITHUB_OWNER" {
  type        = string
  description = "Your GitHub username or organization"
}

variable "GITHUB_TOKEN" {
  type        = string
  sensitive   = true
  description = "Personal access token for GitHub"
}