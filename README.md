# terraform-aws-eks
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.72 |
| <a name="requirement_docker"></a> [docker](#requirement\_docker) | ~> 3.0.1 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.4.1 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 2.0.2 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.67.0 |
| <a name="provider_aws.virginia"></a> [aws.virginia](#provider\_aws.virginia) | 5.67.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws-auth"></a> [aws-auth](#module\_aws-auth) | terraform-aws-modules/eks/aws//modules/aws-auth | ~> 20.0 |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 20.8.3 |
| <a name="module_eks_blueprints_addons"></a> [eks\_blueprints\_addons](#module\_eks\_blueprints\_addons) | aws-ia/eks-blueprints-addons/aws | 1.16.3 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.6.0 |

## Resources

| Name | Type |
|------|------|
| [aws_subnet.db_private_az_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.db_private_bz_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_ecrpublic_authorization_token.token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecrpublic_authorization_token) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eks_version"></a> [eks\_version](#input\_eks\_version) | EKS version for the AWS instance | `string` | `"1.30"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | project name for the AWS instance | `string` | `"eks-test-uat"` | no |
| <a name="input_region"></a> [region](#input\_region) | region for the AWS instance | `string` | `"ap-southeast-2"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for the AWS resources | `map(string)` | <pre>{<br>  "Environment": "UAT",<br>  "ManagedBy": "Terraform",<br>  "Project": "karpenter-uat"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Cluster name of the EKS cluster |
| <a name="output_configure_kubectl"></a> [configure\_kubectl](#output\_configure\_kubectl) | Connect eks cluster |
| <a name="output_node_instance_role_name"></a> [node\_instance\_role\_name](#output\_node\_instance\_role\_name) | IAM Role name that each Karpenter node will use |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID that the EKS cluster is using |
<!-- END_TF_DOCS -->