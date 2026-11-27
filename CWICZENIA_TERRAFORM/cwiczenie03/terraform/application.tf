# Aplikację wdraża Terraform przez natywny provisioner SSH, bez osobnego joba deploy.
# Zmiana kodu skryptów, VM, obrazu lub rewizji ponawia deploy bez odtwarzania VM.
resource "terraform_data" "application" {
  triggers_replace = [
    digitalocean_droplet.vm.id,
    var.image_reference,
    var.container_name,
    var.deployment_revision,
    filesha256("${path.module}/files/bootstrap.sh"),
    filesha256("${path.module}/files/deploy.sh.tftpl"),
  ]

  depends_on = [digitalocean_firewall.vm]

  connection {
    type        = "ssh"
    user        = "root"
    host        = digitalocean_droplet.vm.ipv4_address
    private_key = tls_private_key.ssh.private_key_openssh
    timeout     = "10m"
    script_path = "/root/cw03-%RAND%.sh"
  }

  provisioner "remote-exec" {
    script = "${path.module}/files/bootstrap.sh"
  }

  # Ephemeral sekrety są używane tylko w dozwolonym kontekście provisionera.
  # Nie zapisuj ich w input/triggers_replace, user_data, tfvars ani outputs.
  provisioner "remote-exec" {
    inline = [templatefile("${path.module}/files/deploy.sh.tftpl", {
      image_reference            = var.image_reference
      container_name             = var.container_name
      openweather_api_key_base64 = base64encode(var.openweather_api_key == null ? "" : var.openweather_api_key)
      dockerhub_username_base64  = base64encode(var.dockerhub_username == null ? "" : var.dockerhub_username)
      dockerhub_token_base64     = base64encode(var.dockerhub_token == null ? "" : var.dockerhub_token)
    })]
  }
}
