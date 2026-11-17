########################
# Zmienne pod Ansible
########################

variable "ansible_user" {
  description = "Użytkownik SSH używany przez Ansible"
  type        = string
  default     = "root"
}

locals {
  ansible_inventory_dir   = "${path.module}/inventories/dev"
  ansible_host_name       = digitalocean_droplet.vm.name
  ansible_host_vars_dir   = "${local.ansible_inventory_dir}/host_vars"
  ansible_private_key_rel = "./artefakty/id_ed25519"
}

########################
# Katalogi pod inventory
########################

resource "null_resource" "ansible_dirs" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.ansible_host_vars_dir}"
  }
}

########################
# inventories/dev/hosts.yaml
########################

resource "local_file" "ansible_hosts_yaml" {
  filename = "${local.ansible_inventory_dir}/hosts.yaml"

  # Prosta struktura:
  # all:
  #   hosts:
  #     vm-terraform-1:
  content = <<-EOT
all:
  hosts:
    ${local.ansible_host_name}:
EOT

  depends_on = [
    null_resource.ansible_dirs
  ]
}

########################
# inventories/dev/host_vars/<host>.yaml
########################

resource "local_file" "ansible_host_vars_yaml" {
  filename = "${local.ansible_host_vars_dir}/${local.ansible_host_name}.yaml"

  # Tu są szczegóły hosta:
  # - IP
  # - user
  # - klucz prywatny w ./artefakty
  content = <<-EOT
ansible_host: ${digitalocean_droplet.vm.ipv4_address}
ansible_user: ${var.ansible_user}
ansible_ssh_private_key_file: ${local.ansible_private_key_rel}
EOT

  depends_on = [
    null_resource.ansible_dirs,
    local_file.ssh_private_key
  ]
}

########################
# (Opcjonalnie) outputy
########################

output "ansible_inventory_hosts_file" {
  description = "Ścieżka do pliku hosts.yaml dla środowiska dev"
  value       = local_file.ansible_hosts_yaml.filename
}

output "ansible_host_vars_file" {
  description = "Ścieżka do pliku host_vars dla hosta"
  value       = local_file.ansible_host_vars_yaml.filename
}
