# DIGITALOCEAN_TOKEN comes from the environment, never from a tfvars file.
provider "digitalocean" {}

resource "digitalocean_vpc" "app" {
  name     = var.name
  region   = var.region
  ip_range = "10.78.0.0/24"
}

resource "digitalocean_ssh_key" "deploy" {
  name       = "${var.name}-deploy"
  public_key = tls_private_key.deploy.public_key_openssh
}

resource "digitalocean_droplet" "app" {
  name       = var.name
  region     = var.region
  size       = var.droplet_size
  image      = "ubuntu-24-04-x64"
  vpc_uuid   = digitalocean_vpc.app.id
  ssh_keys   = [digitalocean_ssh_key.deploy.fingerprint]
  ipv6       = false
  monitoring = true
  user_data = "#cloud-config\n${yamlencode({
    ssh_pwauth     = false
    ssh_deletekeys = true
    ssh_keys = {
      ed25519_private = tls_private_key.host.private_key_openssh
      ed25519_public  = trimspace(tls_private_key.host.public_key_openssh)
    }
  })}"
}

resource "digitalocean_firewall" "app" {
  name        = "${var.name}-firewall"
  droplet_ids = [digitalocean_droplet.app.id]
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = [var.ssh_cidr]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = tostring(var.app_port)
    source_addresses = [var.app_cidr]
  }
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0"]
  }
}

resource "digitalocean_reserved_ip" "app" {
  region = var.region
}

resource "digitalocean_reserved_ip_assignment" "app" {
  ip_address = digitalocean_reserved_ip.app.ip_address
  droplet_id = digitalocean_droplet.app.id
}
