locals {
# VPC  Attachments
  vpc_attachments_without_default_route_table_association = {
    for k, v in var.vpc_attachments : k => v if lookup(v, "transit_gateway_default_route_table_association", true) != true
  }
  vpc_attachments_without_default_route_table_propagation = {
    for k, v in var.vpc_attachments : k => v if lookup(v, "transit_gateway_default_route_table_propagation", true) != true
  }
  // List of maps with key and route values
  vpc_attachments_with_routes = chunklist(flatten([
    for k, v in var.vpc_attachments : setproduct([map("key", k)], v["tgw_routes"]) if length(lookup(v, "tgw_routes", {})) > 0
  ]), 2)

  vpc_with_routes = chunklist(flatten([
    for k, v in var.vpc_attachments : setproduct([map("key", k)], v["routes"]) if length(lookup(v, "routes", {})) > 0
  ]), 2)

# VPN  Attachments
  vpn_attachments_with_routes = chunklist(flatten([
    for k, v in var.vpn_attachments : setproduct([map("key", k)], v["tgw_routes"]) if length(lookup(v, "tgw_routes", {})) > 0
  ]), 2)
  vpn_attachments_without_default_route_table_propagation = {
    for k, v in var.vpn_attachments : k => v if lookup(v, "transit_gateway_default_route_table_propagation", true) != true
  }
  vpn_attachments_without_default_route_table_association = {
    for k, v in var.vpn_attachments : k => v if lookup(v, "transit_gateway_default_route_table_association", true) != true
  }

}
data "aws_caller_identity" "current" {}

provider "aws" {
  alias  = "primary"
  region = var.region

  dynamic "assume_role" {
    for_each = var.primary_assume_role_arn != "" ? ["true"] : [format("%s", replace(replace(replace(replace(data.aws_caller_identity.current.arn, "/sts/", "iam"),"/assumed-role/","role"),"/[0-9]*$/",""),"//*$/",""))]
    content {
      role_arn = var.primary_assume_role_arn != "" ? var.primary_assume_role_arn : format("%s", replace(replace(replace(replace(data.aws_caller_identity.current.arn, "/sts/", "iam"),"/assumed-role/","role"),"/[0-9]*$/",""),"//*$/",""))
    }
  }
}

provider "aws" {
  alias  = "shared"
  region = var.region

  dynamic "assume_role" {
    for_each = var.shared_assume_role_arn != "" ? ["true"] : [format("%s", replace(replace(replace(replace(data.aws_caller_identity.current.arn, "/sts/", "iam"),"/assumed-role/","role"),"/[0-9]*$/",""),"//*$/",""))]
    content {
      role_arn = var.shared_assume_role_arn != "" ? var.shared_assume_role_arn : format("%s", replace(replace(replace(replace(data.aws_caller_identity.current.arn, "/sts/", "iam"),"/assumed-role/","role"),"/[0-9]*$/",""),"//*$/",""))
    }
  }
}


#########################
# Route table and routes
#########################
resource "aws_ec2_transit_gateway_route" "this" {
  count = var.create_tgw_route ? length(local.vpc_attachments_with_routes) : 0
  # count = length(local.vpc_attachments_with_routes)
  provider = aws.primary

  destination_cidr_block = local.vpc_attachments_with_routes[count.index][1]["destination_cidr_block"]
  blackhole              = lookup(local.vpc_attachments_with_routes[count.index][1], "blackhole", null)

  transit_gateway_route_table_id = var.transit_gateway_route_table_id
  transit_gateway_attachment_id  = tobool(lookup(local.vpc_attachments_with_routes[count.index][1], "blackhole", false)) == false ? aws_ec2_transit_gateway_vpc_attachment.this[local.vpc_attachments_with_routes[count.index][0]["key"]].id : null
}

###########################################################
# VPC Attachments, route table association and propagation
###########################################################
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = var.create_tgw_route ? var.vpc_attachments : {}

  provider = aws.shared
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = each.value["vpc_id"]
  subnet_ids         = each.value["subnet_ids"]

  dns_support                                     = lookup(each.value, "dns_support", true) ? "enable" : "disable"
  ipv6_support                                    = lookup(each.value, "ipv6_support", false) ? "enable" : "disable"
  transit_gateway_default_route_table_association = lookup(each.value, "transit_gateway_default_route_table_association", true)
  transit_gateway_default_route_table_propagation = lookup(each.value, "transit_gateway_default_route_table_propagation", true)

  tags = merge(
    {
      Name = format("%s-%s", var.name, each.key)
    },
    var.tags,
    var.tgw_vpc_attachment_tags,
  )
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = local.vpc_attachments_without_default_route_table_association
  provider = aws.primary
  // Create association if it was not set already by aws_ec2_transit_gateway_vpc_attachment resource
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = local.vpc_attachments_without_default_route_table_propagation
  provider = aws.primary
  // Create association if it was not set already by aws_ec2_transit_gateway_vpc_attachment resource
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

#########################
# Update route for VPC attachment
#########################
resource "aws_route" "this" {
  count = var.create_tgw_route ? length(local.vpc_with_routes) : 0
  # count                  = length(local.vpc_with_routes)
  provider               = aws.shared
  route_table_id         = lookup(local.vpc_with_routes[count.index][1], "route_table_id", null ) != null ?  local.vpc_with_routes[count.index][1]["route_table_id"] : null
  destination_cidr_block = lookup(local.vpc_with_routes[count.index][1], "destination_cidr_block", null ) != null ?  local.vpc_with_routes[count.index][1]["destination_cidr_block"] : null
  transit_gateway_id     = var.transit_gateway_id
}

// VPN attachment routes
resource "aws_ec2_transit_gateway_route" "vpn" {
  count = length(local.vpn_attachments_with_routes)
  provider = aws.primary
  destination_cidr_block = local.vpn_attachments_with_routes[count.index][1]["destination_cidr_block"]
  blackhole              = lookup(local.vpn_attachments_with_routes[count.index][1], "blackhole", null)

  transit_gateway_route_table_id = var.transit_gateway_route_table_id
  transit_gateway_attachment_id  = var.transit_gateway_attachment_id
  # transit_gateway_attachment_id  = tobool(lookup(local.vpn_attachments_with_routes[count.index][1], "blackhole", false)) == false ? aws_vpn_connection.vpn[local.vpn_attachments_with_routes[count.index][0]["key"]].transit_gateway_attachment_id : null
}

resource "aws_ec2_transit_gateway_route_table_association" "vpn" {
  for_each = local.vpn_attachments_without_default_route_table_association
  provider = aws.primary
  // Create association if it was not set already by aws_ec2_transit_gateway_vpc_attachment resource
  # transit_gateway_attachment_id  = aws_vpn_connection.vpn[each.key].transit_gateway_attachment_id
  transit_gateway_attachment_id  = var.transit_gateway_attachment_id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn" {
  for_each = local.vpn_attachments_without_default_route_table_association
  provider = aws.primary
  // Create association if it was not set already by aws_ec2_transit_gateway_vpc_attachment resource
  # transit_gateway_attachment_id  = aws_vpn_connection.vpn[each.key].transit_gateway_attachment_id
  transit_gateway_attachment_id  = var.transit_gateway_attachment_id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}
