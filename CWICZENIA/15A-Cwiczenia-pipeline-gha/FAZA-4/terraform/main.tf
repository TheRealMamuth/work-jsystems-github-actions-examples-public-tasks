locals {
  resource_name = "${var.student_name}-pogoda-f4-${var.environment}-${random_id.suffix.hex}"
}

# Losowy sufiks jest trwały w state danego workspace i obejmuje wszystkie
# nazwy zasobów DigitalOcean, także klucz SSH i firewall.
resource "random_id" "suffix" {
  byte_length = 3

  lifecycle {
    precondition {
      condition     = contains(["dev", "prod"], terraform.workspace) && var.environment == terraform.workspace
      error_message = "Wybierz workspace dev lub prod zgodny z environment. Workspace default jest zabroniony."
    }
  }
}

# Na życzenie ćwiczenie generuje parę kluczy w Terraform. Klucz prywatny
# znajduje się w lokalnym state; runner i jego kopie state muszą być chronione.
resource "tls_private_key" "deployment" {
  algorithm = "ED25519"
}

resource "digitalocean_ssh_key" "deployment" {
  name       = "${local.resource_name}-deploy"
  public_key = tls_private_key.deployment.public_key_openssh
}

resource "digitalocean_droplet" "application" {
  name       = local.resource_name
  image      = "ubuntu-24-04-x64"
  region     = var.region
  size       = var.droplet_size
  ssh_keys   = [digitalocean_ssh_key.deployment.fingerprint]
  user_data  = file("${path.module}/cloud-init.yaml")
  ipv6       = false
  backups    = false
  monitoring = false

  # Bez vpc_uuid DigitalOcean używa istniejącej domyślnej VPC regionu.
  # To ćwiczenie nie tworzy żadnych sieci.
}

resource "digitalocean_firewall" "application" {
  name        = "${local.resource_name}-firewall"
  droplet_ids = [digitalocean_droplet.application.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = [var.ssh_allowed_cidr]
  }

  # Bez domeny aplikacja jest dostępna pod http://<public_ip>/.
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0"]
  }

  # Pobieranie pakietów, obrazu Docker Hub oraz danych OpenWeather.
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
