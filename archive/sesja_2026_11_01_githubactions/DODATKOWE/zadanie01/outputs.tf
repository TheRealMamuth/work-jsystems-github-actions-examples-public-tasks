########################
# Przydatne outputy
########################

output "droplet_ip" {
  description = "Adres IP Dropleta"
  value       = digitalocean_droplet.vm.ipv4_address
}

output "ssh_private_key_path" {
  description = "Ścieżka do klucza prywatnego"
  value       = local_file.ssh_private_key.filename
  sensitive   = true
}

output "ssh_public_key_path" {
  description = "Ścieżka do klucza publicznego"
  value       = local_file.ssh_public_key.filename
}
