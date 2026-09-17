output "public_ip_address" {
  value = digitalocean_droplet.main.ipv4_address
}
