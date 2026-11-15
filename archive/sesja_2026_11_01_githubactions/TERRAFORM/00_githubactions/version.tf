# Jest to plik gdzie jest przechowywana informacja o wersji naszego terraforma potrzebna do uruchamienia tego kodu.
# Jest tez tu informacja o naszych potrzebnych providerach i ich wersji.

terraform {
  required_version = ">= 1.5"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
    }
  }
  backend "pg" {
  }
}
