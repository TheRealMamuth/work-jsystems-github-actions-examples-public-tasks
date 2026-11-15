resource "random_id" "suffix" {
  byte_length = 3
}

resource "digitalocean_droplet" "example" {
  image  = "ubuntu-24-04-x64"
  name   = "example-${random_id.suffix.hex}"
  region = "fra1"
  size   = "s-1vcpu-1gb"
  vpc_uuid = digitalocean_vpc.example.id
}

resource "digitalocean_vpc" "example" {
  name   = "example-vpc-${random_id.suffix.hex}"
  region = "fra1"
  ip_range = "10.114.1.0/24"
}