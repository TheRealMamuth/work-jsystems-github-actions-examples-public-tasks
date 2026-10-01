resource "digitalocean_vpc" "this" {
  name        = "${local.name}-vpc"
  description = "VPC dla ${local.name}, zarządzane przez Terraform."
  region      = var.region
  ip_range    = var.vpc_ip_range
}
