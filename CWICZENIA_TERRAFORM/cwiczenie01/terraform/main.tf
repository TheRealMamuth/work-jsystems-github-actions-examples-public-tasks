# Wartość jest zapisana w state. Kolejne plan/apply zachowują ten sam sufiks.
resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "private_key" {
  filename             = "${path.module}/.keys/id_ed25519"
  content              = tls_private_key.ssh.private_key_openssh
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "digitalocean_ssh_key" "student" {
  name       = "${var.vm_name}-${random_string.suffix.result}-ssh"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "digitalocean_vpc" "lab" {
  name     = "${var.vpc_name}-${random_string.suffix.result}"
  region   = var.region
  ip_range = var.vpc_cidr
}

resource "digitalocean_droplet" "vm" {
  name     = "${var.vm_name}-${random_string.suffix.result}"
  region   = var.region
  image    = var.vm_image
  size     = var.vm_size
  vpc_uuid = digitalocean_vpc.lab.id
  ssh_keys = [digitalocean_ssh_key.student.fingerprint]
  ipv6     = false
}

resource "digitalocean_firewall" "vm" {
  name        = "${var.firewall_name}-${random_string.suffix.result}"
  droplet_ids = [digitalocean_droplet.vm.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = [var.ssh_allowed_cidr]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
