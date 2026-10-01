terraform {
  required_version = ">= 1.7.0, < 2.0.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

variable "token" {
  description = "Token API DigitalOcean odczytywany z lokalnego, ignorowanego pliku terraform.tfvars."
  type        = string
  sensitive   = true
  default     = null
}

variable "digitalocean_token" {
  description = "Token API DigitalOcean odczytywany z lokalnego, ignorowanego pliku terraform.tfvars."
  type        = string
  sensitive   = true
  default     = null
}

# Token jest przekazywany przez zmienną sensitive z lokalnego terraform.tfvars.
provider "digitalocean" {
  token = var.digitalocean_token
}

provider "random" {}
