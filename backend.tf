terraform {
  backend "s3" {
    bucket  = "cibexon-eks-terraform-state"
    key     = "eks/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}
