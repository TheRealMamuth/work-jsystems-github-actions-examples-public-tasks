########################
# Klucz SSH – TLS
########################

resource "tls_private_key" "vm" {
  algorithm = "ED25519"
}

# Zapis klucza prywatnego do pliku
resource "local_file" "ssh_private_key" {
  filename        = "${path.module}/artefakty/id_ed25519"
  content         = tls_private_key.vm.private_key_openssh
  file_permission = "0600"
}

# Zapis klucza publicznego do pliku
resource "local_file" "ssh_public_key" {
  filename        = "${path.module}/artefakty/id_ed25519.pub"
  content         = tls_private_key.vm.public_key_openssh
  file_permission = "0644"
}

########################
# DigitalOcean SSH Key
########################

resource "digitalocean_ssh_key" "vm_key" {
  name       = "vm-ssh-key"
  public_key = tls_private_key.vm.public_key_openssh
}
