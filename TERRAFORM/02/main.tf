resource "digitalocean_droplet" "main" {
  name   = "piotr-koska-github-actions-droplet"
  region = "fra1"
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-24-04-x64"
  ssh_keys = [
    digitalocean_ssh_key.main.id
  ]
}

resource "digitalocean_project" "main" {
  name        = "piotr-koska-github-actions-project"
  description = "Project for GitHub Actions examples"
  purpose     = "Testing and learning"
  environment = "Development"
}

resource "digitalocean_project_resources" "main" {
  project = digitalocean_project.main.id
  resources = [
    digitalocean_droplet.main.urn
  ]
}

resource "digitalocean_vpc" "main" {
  name     = "piotr-koska-github-actions-vpc"
  region   = "fra1"
  ip_range = "10.113.10.0/24" # <- uzjcie sowej sieci
}

resource "tls_private_key" "main" {
  algorithm = "ED25519"
}

resource "digitalocean_ssh_key" "main" {
  name       = "piotr-koska-github-actions-ssh-key"
  public_key = tls_private_key.main.public_key_openssh
}

resource "digitalocean_firewall" "main" {
  name        = "piotr-koska-github-actions-firewall"
  droplet_ids = [digitalocean_droplet.main.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
}
