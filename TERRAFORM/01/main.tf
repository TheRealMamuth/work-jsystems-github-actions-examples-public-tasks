resource "digitalocean_droplet" "main" {
  name   = "piotr-koska-github-actions-droplet" # dajcie sowje imie
  region = "fra1"
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-24-04-x64"
}
