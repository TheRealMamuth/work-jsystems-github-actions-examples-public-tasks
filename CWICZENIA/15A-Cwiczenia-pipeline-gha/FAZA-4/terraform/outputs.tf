output "droplet_id" {
  description = "ID VM; pozwala rozróżniać klucze hosta SSH po odtworzeniu maszyny."
  value       = digitalocean_droplet.application.id
}

output "public_ip" {
  description = "Publiczny IPv4 hosta wybranego środowiska."
  value       = digitalocean_droplet.application.ipv4_address
}

output "app_url" {
  description = "Adres WWW i baza API aplikacji bez domeny."
  value       = "http://${digitalocean_droplet.application.ipv4_address}"
}

output "ssh_private_key_openssh" {
  description = "Prywatny klucz SSH dla kroku deploy. Zapisuj tylko do tymczasowego pliku 0600, nigdy do logów lub artefaktów."
  value       = tls_private_key.deployment.private_key_openssh
  sensitive   = true
}

output "ssh_public_key" {
  description = "Publiczny klucz SSH zarejestrowany na koncie DigitalOcean."
  value       = tls_private_key.deployment.public_key_openssh
}
