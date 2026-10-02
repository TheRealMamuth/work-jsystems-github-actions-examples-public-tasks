variable "name" {
  description = "Resource name; keep it stable between runs."
  type        = string
  default     = "full-deploy"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.name))
    error_message = "Use 3-31 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "ssh_cidr" {
  description = "Public IPv4 of the current runner, with /32; never open SSH to the world."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.ssh_cidr)) && can(regex("/32$", var.ssh_cidr))
    error_message = "ssh_cidr must be one IPv4 address with /32."
  }
}

variable "app_cidr" {
  description = "IPv4 CIDR allowed to reach the application."
  type        = string
  default     = "0.0.0.0/0"
  validation {
    condition     = can(cidrnetmask(var.app_cidr))
    error_message = "app_cidr must be an IPv4 CIDR."
  }
}

variable "app_port" {
  type    = number
  default = 80
  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535 && var.app_port != 22 && floor(var.app_port) == var.app_port
    error_message = "Use an integer TCP port from 1 to 65535, other than SSH port 22."
  }
}

variable "region" {
  type    = string
  default = "fra1"
}

variable "droplet_size" {
  type    = string
  default = "s-1vcpu-1gb"
}
