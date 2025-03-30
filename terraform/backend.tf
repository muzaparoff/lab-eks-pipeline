terraform {
  backend "s3" {
    bucket         = "lab-eks-terraform-state-6368"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
