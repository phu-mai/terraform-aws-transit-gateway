
locals {
  primary_assume_role_arn = "arn:aws:iam::xxxxxxxxxxxx:role/AssumedRole"
  shared_assume_role_arn  = "arn:aws:iam::yyyyyyyyyyyy:role/AssumedRole"
}

module "tgw" {
  source  = "../modules/terraform-aws-transit-gateway"

  name            = "tgw-poc-cxa"
  description     = "My TGW shared with several other AWS accounts"
  amazon_side_asn = 64532
  enable_auto_accept_shared_attachments = true
  ram_allow_external_principals = true
  ram_principals = [842341796448]
  tags = {
    Purpose = "tgw-complete-example"
  }
}

module "tgw_primary_route" {
  source              = "../modules/transit-gateway-routes/"
  name                = "tgw-primary-routes"
  region              = "ap-southeast-1"
  primary_assume_role_arn = local.primary_assume_role_arn
  shared_assume_role_arn  = local.shared_assume_role_arn
  transit_gateway_id  = module.tgw.this_ec2_transit_gateway_id
  transit_gateway_route_table_id = module.tgw.this_ec2_transit_gateway_route_table_id
  vpc_attachments = {
    vpc_infra = {
      vpc_id       = "vpc-0bb638xxxxxxxx"
      subnet_ids   = ["subnet-032c01c0xxxxxxxx","subnet-00568cadxxxxxxxx","subnet-0478fc56xxxxxxxx"]
      dns_support  = true
      ipv6_support = false
      routes = [
        {
          route_table_id         = "rtb-01c35c93xxxxx"
          destination_cidr_block = "10.40.0.0/16"
        }
      ]
      tgw_routes = [
        {
          destination_cidr_block = "200.0.0.0/16"
        },
        {
          blackhole              = true
          destination_cidr_block = "0.0.0.0/0"
        }
      ]
    }
  }
  vpn_attachments = {
    vpc_infra_vpn  = {
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
      customer_gateway_id = "cgw-0244fddc8d8f24be0"
      type                = "ipsec.1"
      tgw_routes = [
        {
          destination_cidr_block = "30.0.0.0/16"
        },
        {
          destination_cidr_block = "20.0.0.0/16"
        }
      ]
    }
  }
}

module "tgw_shared_route" {
  source              = "../modules/transit-gateway-routes/"
  name                = "tgw-shared-routes"
  region              = "ap-southeast-1"
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

    vpc_cxa_poc   = {
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

  # vpc_attachments
  }
}
