data "cloudinit_config" "main" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content = templatefile("./_files/cloud_init.yaml", {
      cloud_init_user = var.droplets_config_system_user
      cloud_init_pass = var.droplets_config_system_pass
      ssh_public_key  = tls_private_key.vm.public_key_openssh
    })
  }
}
