## NOTE: It's going to use your AWS_REGION or AWS_DEFAULT_REGION environment variable,
## but you can define which on to use in terraform.tfvars file as well, or pass it as an argument
## in the CLI like this "terraform apply -var 'region=eu-west-1'"
variable "region" {
  description = "region for the AWS instance"
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "project name for the AWS instance"
  type        = string
  default     = "eks-cnsre-uat"
}

variable "tags" {
  description = "Tags for the AWS resources"
  type        = map(string)
  default = {
    "Project"    = "cnsre-uat"
    "ManagedBy"  = "Terraform"
    "Environment" = "UAT"
  }
}

variable "eks_version" {
  description = "EKS version for the AWS instance"
  type        = string
  default     = "1.30"
}
