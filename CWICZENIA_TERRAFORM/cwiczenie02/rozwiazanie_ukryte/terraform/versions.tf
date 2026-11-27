terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  # Pipeline przekazuje bezwzględny path podczas terraform init.
  # Stan pozostaje lokalnym plikiem na trwałym dysku self-hosted runnera.
  backend "local" {}

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.109.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.4.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9.1"
    }
  }
}

# Provider odczytuje token ze zmiennej środowiskowej DIGITALOCEAN_TOKEN.
# Bez zmiennej token i bez tfvars z tokenem; backend nie wymaga poświadczeń.
provider "digitalocean" {}
