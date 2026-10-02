output "ansible_inventory" {
  description = "Ansible YAML inventory represented as a JSON object, without runner-local paths."
  value = {
    all = {
      children = {
        app = {
          hosts = {
            full_deploy = {
              ansible_host               = digitalocean_reserved_ip.app.ip_address
              ansible_user               = "root"
              ansible_python_interpreter = "/usr/bin/python3"
              app_port                   = var.app_port
            }
          }
        }
      }
    }
  }
}

output "ssh_private_key" {
  description = "Sensitive! Redirect terraform output -raw directly to a protected temporary file."
  value       = tls_private_key.deploy.private_key_openssh
  sensitive   = true
}

output "ssh_known_hosts" {
  description = "Server identity for StrictHostKeyChecking=yes; no blind ssh-keyscan."
  value       = "${digitalocean_reserved_ip.app.ip_address} ${trimspace(tls_private_key.host.public_key_openssh)}"
}

output "app_url" {
  value = "http://${digitalocean_reserved_ip.app.ip_address}:${var.app_port}"
}
