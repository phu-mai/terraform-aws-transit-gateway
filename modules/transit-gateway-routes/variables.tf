variable "create_tgw_route" {
  description = "Controls if TGW should be created (it affects almost all resources)"
  type        = bool
  default     = true
}
variable "region" {
  description = "provides details about a specific AWS region"
  type        = string
  default     = ""
}

variable "primary_assume_role_arn" {
  description = "Primary assume role arn of TGW"
  type        = string
  default     = ""
}
variable "shared_assume_role_arn" {
  description = "Shared assume role arn of TGW"
  type        = string
  default     = ""
}

variable "transit_gateway_id" {
  description = "Identifier of EC2 Transit Gateway."
  type        = string
  default     = ""
}

variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

// VPC attachments
variable "vpc_attachments" {
  description = "Maps of maps of VPC details to attach to TGW. Type 'any' to disable type validation by Terraform."
  type        = any
  default     = {}
}
// VPn attachments
variable "vpn_attachments" {
  description = "Maps of maps of VPN details to attach to TGW. Type 'any' to disable type validation by Terraform."
  type        = any
  default     = {}
}
// TGW Route Table association and propagation
variable "transit_gateway_route_table_id" {
  description = "Identifier of EC2 Transit Gateway Route Table to use with the Target Gateway when reusing it between multiple TGWs"
  type        = string
  default     = null
}

// Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "tgw_vpc_attachment_tags" {
  description = "Additional tags for VPC attachments"
  type        = map(string)
  default     = {}
}

variable "transit_gateway_attachment_id" {
  type        = string
  default     = null
}
