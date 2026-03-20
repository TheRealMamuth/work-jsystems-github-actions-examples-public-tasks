resource "digitalocean_droplet" "main" {
  name   = "piotr-koska-github-actions-droplet"
  region = "fra1"
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-24-04-x64"
  ssh_keys = [
    digitalocean_ssh_key.main.id,
    digitalocean_ssh_key.own.id
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
  ip_range = "10.10.10.0/24"
}

resource "tls_private_key" "main" {
  algorithm = "ED25519"
}

resource "digitalocean_ssh_key" "main" {
  name       = "piotr-koska-github-actions-ssh-key"
  public_key = tls_private_key.main.public_key_openssh
}

resource "digitalocean_ssh_key" "own" {
  name       = "piotr-koska-github-actions-own-ssh-key"
  public_key = var.own_ssh_public_key

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

  inbound_rule {
    protocol         = "tcp"
    port_range       = "8080"
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
  filename = "${path.module}/inventories/hosts.yaml"

  content = <<-EOT
    digitalocean:
      hosts:
        ${digitalocean_droplet.main.name}:
  EOT
}

resource "local_file" "ansible_host_vars" {
  filename = "${path.module}/host_vars/${digitalocean_droplet.main.name}.yaml"

  content = <<-EOT
    ansible_user: root
    ansible_host: ${digitalocean_droplet.main.ipv4_address}
    ansible_ssh_private_key_file: ${path.module}/ssh_keys/id_ed25519
  EOT
}

resource "local_file" "ssh_private_key" {
  filename        = "${path.module}/ssh_keys/id_ed25519"
  file_permission = "0600"
  content         = tls_private_key.main.private_key_openssh
}
