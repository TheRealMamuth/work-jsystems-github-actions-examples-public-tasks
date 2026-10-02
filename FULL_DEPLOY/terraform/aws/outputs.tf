output "ansible_inventory" {
  description = "Ansible YAML inventory represented as a JSON object, without runner-local paths."
  value = {
    all = {
      children = {
        app = {
          hosts = {
            full_deploy = {
              ansible_host               = aws_eip.app.public_ip
              ansible_user               = "ubuntu"
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
  value       = "${aws_eip.app.public_ip} ${trimspace(tls_private_key.host.public_key_openssh)}"
}

output "app_url" {
  value = "http://${aws_eip.app.public_ip}:${var.app_port}"
}
