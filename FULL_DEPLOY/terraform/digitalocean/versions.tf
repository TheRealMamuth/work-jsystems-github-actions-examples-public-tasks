terraform {
  required_version = ">= 1.11.0, < 2.0.0"
  backend "pg" {}
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "= 2.103.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "= 4.4.1"
    }
  }
}
