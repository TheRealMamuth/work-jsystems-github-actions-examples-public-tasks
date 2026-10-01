locals {
    firewall_configuration = jsondecode(file("${path.root}/files/firewall_configurations/firewall.json"))
}

variable "do_token" {
  type = string
  description = "Digital Ocean Token"
  sensitive = true
}

variable "droplet_name" {
  type = string
  description = "Droplet Name"
}

variable "droplet_image" {
  type = string
  description = "Droplet Image"
}

variable "droplet_size" {
  type = string
  description = "Droplet Size"
}

variable "region" {
  type = string
  description = "Region"
}

variable "vpc_name" {
  type = string
  description = "VPC Name"
}

variable "vpc_ip_range" {
  type = string
  description = "VPC IP Range"
}

variable "firewall_name" {
  type = string
  description = "Firewall Name"
}

variable "ssh_key_name" {
  type = string
  description = "SSH Key Name"
}
