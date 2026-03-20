variable "digitalocean_token" {
  description = "This is API key for cloud - this is secret"
  sensitive   = true
}

variable "project_environment" {
  description = "This is Type of environment for project - this is not secret, but we want to validate it"
  type        = string
  default     = "Development"

  validation {
    condition     = contains(["Development", "Production", "Staging"], var.project_environment)
    error_message = "Dozwolone wartosci environment to: Development, Production, Staging."
  }
}

variable "own_ssh_public_key" {
  description = "This is your own SSH public key - this is not secret, but we want to validate it"
  type        = string
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH8435K6g4GM6CkTTVc+uQ6IAbQolZL/fK2U/ri+ou/L piotrkoska@Piotrs-MacBook-Pro.local"

  validation {
    condition     = can(regex("^ssh-(rsa|ed25519)\\s+[A-Za-z0-9+/]+={0,3}(\\s+.+)?$", var.own_ssh_public_key))
    error_message = "SSH public key musi zaczynac sie od 'ssh-rsa' lub 'ssh-ed25519', a nastepnie zawierac klucz w formacie base64."
  }
}

variable "ssh_name" {
  description = "This is name for SSH key - this is not secret"
  type        = string

  validation {
    condition     = length(var.ssh_name) > 0
    error_message = "Nazwa klucza SSH nie moze byc pusta."
  }
}

variable "droplet_name" {
  description = "This is name for Droplet - this is not secret"
  type        = string

  validation {
    condition     = length(var.droplet_name) > 0
    error_message = "Nazwa Dropleta nie moze byc pusta."
  }
}

variable "droplet_region" {
  description = "This is region for Droplet - this is not secret"
  type        = string
  default = "fra1"

  validation {
    condition     = length(var.droplet_region) > 0
    error_message = "Region Dropleta nie moze byc pusty."
  }
}

variable "droplet_size" {
  description = "This is size for Droplet - this is not secret"
  type        = string
  default = "s-1vcpu-1gb"

  validation {
    condition     = length(var.droplet_size) > 0
    error_message = "Rozmiar Dropleta nie moze byc pusty."
  }
}

variable "droplet_image" {
  description = "This is image for Droplet - this is not secret"
  type        = string
  default = "ubuntu-24-04-x64"

  validation {
    condition     = length(var.droplet_image) > 0
    error_message = "Obraz Dropleta nie moze byc pusty."
  }
}

variable "project_name" {
  description = "This is name for Project - this is not secret"
  type        = string

  validation {
    condition     = length(var.project_name) > 0
    error_message = "Nazwa Projektu nie moze byc pusta."
  }
}

variable "project_description" {
  description = "This is description for Project - this is not secret"
  type        = string
}

variable "project_purpose" {
  description = "This is purpose for Project - this is not secret"
  type        = string
}

variable "vpc_name" {
  description = "This is name for VPC - this is not secret"
  type        = string

  validation {
    condition     = length(var.vpc_name) > 0
    error_message = "Nazwa VPC nie moze byc pusta."
  }
}

variable "vpc_region" {
  description = "This is region for VPC - this is not secret"
  type        = string
  default = "fra1"

  validation {
    condition     = length(var.vpc_region) > 0
    error_message = "Region VPC nie moze byc pusty."
  }
}

variable "vpc_ip_range" {
  description = "This is IP range for VPC - this is not secret"
  type        = string

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]+$", var.vpc_ip_range))
    error_message = "Zakres IP musi byc w formacie CIDR, np. '192.168.0.0/16'."
  }
}
