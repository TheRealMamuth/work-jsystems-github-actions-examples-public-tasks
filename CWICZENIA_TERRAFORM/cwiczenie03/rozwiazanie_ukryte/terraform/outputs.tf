output "vm_id" {
  description = "Identyfikator utworzonej VM DigitalOcean."
  value       = digitalocean_droplet.vm.id
}

output "vm_name" {
  description = "Pełna nazwa VM ze stałym losowym sufiksem."
  value       = digitalocean_droplet.vm.name
}

output "public_ip" {
  description = "Publiczny adres IPv4 VM."
  value       = digitalocean_droplet.vm.ipv4_address
}

output "private_ip" {
  description = "Prywatny adres IPv4 VM w utworzonej VPC."
  value       = digitalocean_droplet.vm.ipv4_address_private
}

output "vpc_id" {
  description = "Identyfikator utworzonej VPC."
  value       = digitalocean_vpc.lab.id
}

output "vpc_cidr" {
  description = "Zakres adresacji prywatnej VPC."
  value       = digitalocean_vpc.lab.ip_range
}

output "firewall_name" {
  description = "Pełna nazwa firewalla przypisanego do VM."
  value       = digitalocean_firewall.vm.name
}

output "private_key_path" {
  description = "Lokalna ścieżka wygenerowanego pliku klucza SSH; output nie zawiera jego wartości."
  value       = abspath(local_sensitive_file.private_key.filename)
}

output "ssh_public_key" {
  description = "Publiczny klucz SSH w formacie OpenSSH, zarejestrowany w DigitalOcean."
  value       = tls_private_key.ssh.public_key_openssh
}

output "ssh_private_key" {
  description = "Prywatny klucz SSH w formacie OpenSSH; jawny odczyt: terraform output -raw ssh_private_key."
  value       = tls_private_key.ssh.private_key_openssh
  sensitive   = true
}

output "ssh_command" {
  description = "Polecenie SSH do wykonania lokalnie po udanym apply."
  value       = "ssh -i \"${abspath(local_sensitive_file.private_key.filename)}\" root@${digitalocean_droplet.vm.ipv4_address}"
}

output "app_url" {
  description = "Publiczny URL HTTP aplikacji przez Nginx."
  value       = "http://${digitalocean_droplet.vm.ipv4_address}"
}

output "image_reference" {
  description = "Dokładny obraz aplikacji przypięty digestem SHA256."
  value       = var.image_reference
}
