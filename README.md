# AWS Transit Gateway Terraform module

Terraform module which creates Transit Gateway resources on AWS.

This type of resources are supported:

* [Transit Gateway](https://www.terraform.io/docs/providers/aws/r/ec2_transit_gateway.html)
* [Transit Gateway Route](https://www.terraform.io/docs/providers/aws/r/ec2_transit_gateway_route.html)
* [Transit Gateway Route Table](https://www.terraform.io/docs/providers/aws/r/ec2_transit_gateway_route_table.html)
* [Transit Gateway Route Table Association](https://www.terraform.io/docs/providers/aws/r/ec2_transit_gateway_route_table_association.html)
* [Transit Gateway Route Table Propagation](https://www.terraform.io/docs/providers/aws/r/ec2_transit_gateway_route_table_propagation.html)
* [Transit Gateway VPC Attachment](https://www.terraform.io/docs/providers/aws/r/ec2_transit_gateway_vpc_attachment.html)

* [Transit Gateway VPC Attachment Accepter]

## Terraform versions

Only Terraform 0.12 or newer is supported.

## Usage with VPC module

```hcl
module "tgw" {
  source  = "./modules/transit-gateway"
  version = "~> 1.0"
  
  name        = "my-tgw"
  description = "My TGW shared with several other AWS accounts"
  
  enable_auto_accept_shared_attachments = true

  vpc_attachments = {
    vpc = {
      vpc_id       = module.vpc.vpc_id
      subnet_ids   = module.vpc.private_subnets
      dns_support  = true
      ipv6_support = true

      tgw_routes = [
        {
          destination_cidr_block = "30.0.0.0/16"
        },
        {
          blackhole = true
          destination_cidr_block = "40.0.0.0/20"
        }
      ]
    }
  }

  ram_allow_external_principals = true
  ram_principals = [307990089504]

  tags = {
    Purpose = "tgw-complete-example"
  }
}

module "tgw_shared_route" {
  source              = "./modules/transit-gateway-routes/"
  name                = "tgw-shared-routes"
  region              = "u-west-1"
  primary_assume_role_arn = local.primary_assume_role_arn
  shared_assume_role_arn  = local.shared_assume_role_arn
  transit_gateway_id  = module.tgw.this_ec2_transit_gateway_id
  transit_gateway_route_table_id = module.tgw.this_ec2_transit_gateway_route_table_id
  vpc_attachments = {
    vpc_cxa_infra = {
      vpc_id       = "vpc-02008fyyyyyyyy"
      subnet_ids   = ["subnet-0793cf5byyyyyyyy","subnet-0903d770yyyyyyyy","subnet-055578f8yyyyyyyy"]
      dns_support  = true
      ipv6_support = false
      routes = [
        {
          route_table_id         = "rtb-00f0e4yyyyyyyy"
          destination_cidr_block = "10.20.0.0/16"
        },
        {
          route_table_id         = "rtb-0ba6dbyyyyyyyy"
          destination_cidr_block = "10.20.0.0/16"
        }
      ]

      tgw_routes = [
        {
          destination_cidr_block = "20.0.0.0/16"
        }
      ]
    },

    vpc_cxa   = {
      vpc_id       = "vpc-0sdr8fzzzzzz"
      subnet_ids   = ["subnet-0793cf5bzzzzzz","subnet-0903d770zzzzzz","subnet-055578f8zzzzzz"]
      dns_support  = true
      ipv6_support = false

      routes = [
        {
          route_table_id         = "rtb-0ba6dbzzzzzz"
          destination_cidr_block = "10.30.0.0/16"
        }
      ]

      tgw_routes = [
        {
          destination_cidr_block = "30.0.0.0/16"
        }
      ]
    }

  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.0"

  name = "my-vpc"

  cidr = "10.10.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]

  enable_ipv6                                    = true
  private_subnet_assign_ipv6_address_on_creation = true
  private_subnet_ipv6_prefixes                   = [0, 1, 2]
}


```

## Examples

* [Complete example](https://github.com/terraform-aws-modules/terraform-aws-transit-gateway/tree/master/examples/complete) shows TGW in combination with the [VPC module](https://github.com/terraform-aws-modules/terraform-aws-vpc) and [Resource Access Manager (RAM)](https://aws.amazon.com/ram/).
* [Multi-account example](https://github.com/terraform-aws-modules/terraform-aws-transit-gateway/tree/master/examples/multi-account) shows TGW resources shared with different AWS accounts (via [Resource Access Manager (RAM)](https://aws.amazon.com/ram/)).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.7, < 0.14 |
| aws | >= 2.24, < 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 2.24, < 4.0 |

## License

Apache 2 Licensed. See LICENSE for full details.
