resource "digitalocean_droplet" "main" {
  name   = "${var.droplet_name}"
  region = var.droplet_region
  size   = var.droplet_size
  image  = var.droplet_image
  ssh_keys = [
    digitalocean_ssh_key.main.id,
    digitalocean_ssh_key.own.id
  ]
}

resource "digitalocean_project" "main" {
  name        = "${var.project_name}"
  description = var.project_description
  purpose     = var.project_purpose
  environment = var.project_environment
}

resource "digitalocean_project_resources" "main" {
  project = digitalocean_project.main.id
  resources = [
    digitalocean_droplet.main.urn
  ]
}

resource "digitalocean_vpc" "main" {
  name     = "${var.vpc_name}-${var.project_environment}"
  region   = var.vpc_region
  ip_range = var.vpc_ip_range
}

resource "tls_private_key" "main" {
  algorithm = "ED25519"
}

resource "random_string" "main" {
  length  = 8
  special = false
  lower = true
  numeric = true
}

resource "digitalocean_ssh_key" "main" {
  name       = "ansible-github-actions-ssh-key-${var.project_environment}"
  public_key = tls_private_key.main.public_key_openssh
}

resource "digitalocean_ssh_key" "own" {
  name       = "${var.ssh_name}-github-actions-own-ssh-key-${var.project_environment}"
  public_key = var.own_ssh_public_key
  
}

resource "digitalocean_firewall" "main" {
  name        = "github-actions-firewall-${var.project_environment}"
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

  inbound_rule {
    protocol = "tcp"
    port_range = "8080"
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

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventories/${var.project_environment}/hosts.yaml"

  content = <<-EOT
    digitalocean:
      hosts:
        ${digitalocean_droplet.main.name}:
  EOT
}

resource "local_file" "ansible_host_vars" {
  filename = "${path.module}/inventories/${var.project_environment}/host_vars/${digitalocean_droplet.main.name}.yaml"

  content = <<-EOT
    ansible_user: root
    ansible_host: ${digitalocean_droplet.main.ipv4_address}
    ansible_ssh_private_key_file: ${path.module}/${var.project_environment}/ssh_keys/id_ed25519
  EOT
}

resource "local_file" "ssh_private_key" {
  filename = "${path.module}/${var.project_environment}/ssh_keys/id_ed25519"
  file_permission = "0600"
  content = tls_private_key.main.private_key_openssh
}
