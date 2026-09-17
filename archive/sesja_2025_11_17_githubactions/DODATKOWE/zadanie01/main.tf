########################
# Droplet (maszyna wirtualna)
########################

resource "digitalocean_droplet" "vm" {
  name   = var.name
  region = var.region
  size   = var.droplet_size
  image  = var.droplet_image

  # Podpinamy wcześniej utworzony klucz SSH
  ssh_keys = [
    digitalocean_ssh_key.vm_key.fingerprint
  ]

  ipv6          = false
  user_data     = data.cloudinit_config.main.rendered
  monitoring    = true
  backups       = false
  droplet_agent = true
  vpc_uuid = digitalocean_vpc.vm_vpc.id
}

resource "digitalocean_vpc" "vm_vpc" {
  name   = "gha-vpc-${var.name}"
  region = var.region
  ip_range = var.vpc_ip_range
}

########################
# Firewall – pełne otwarcie TCP/UDP
########################

resource "digitalocean_firewall" "vm_fw" {
  name = "gha-fw-${var.name}"

  droplet_ids = [
    digitalocean_droplet.vm.id
  ]

  # CAŁY ruch przychodzący TCP
  inbound_rule {
    protocol         = "tcp"
    port_range       = "1-65535"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # CAŁY ruch przychodzący UDP
  inbound_rule {
    protocol         = "udp"
    port_range       = "1-65535"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # CAŁY ruch wychodzący TCP
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # CAŁY ruch wychodzący UDP
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

########################
# Projekt i przypisanie Dropleta
########################

resource "digitalocean_project" "project" {
  name        = "gha-project-${var.name}"
  description = "Projekt utworzony przez Terraform"
  purpose     = "Web Application"
  environment = "Development"
}

resource "digitalocean_project_resources" "project_resources" {
  project = digitalocean_project.project.id

  resources = [
    digitalocean_droplet.vm.urn
  ]
}
