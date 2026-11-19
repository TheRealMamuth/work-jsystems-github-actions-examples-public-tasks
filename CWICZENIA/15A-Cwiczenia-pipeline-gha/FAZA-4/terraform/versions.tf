terraform {
  required_version = ">= 1.10, < 2.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.106.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
  }

  # Pipeline podaje path oraz workspace_dir na trwałym dysku runnera.
  # terraform workspace select -or-create dev|prod rozdziela oba pliki state.
  # State pozostaje poza checkoutem i katalogiem RUNNER_TEMP.
  backend "local" {}
}

# Token pochodzi wyłącznie ze zmiennej środowiskowej DIGITALOCEAN_TOKEN.
# Nie dodawaj tokenu do tfvars ani do argumentów wywołania Terraform.
provider "digitalocean" {}
