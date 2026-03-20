terraform {
  required_version = "> 1.13"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "> 2.0"
    }
  }
  cloud {

    organization = "piotr_koska_test"

    workspaces {
      name = "github_action_szkolenie"
    }
  }
}
