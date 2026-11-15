mock_provider "digitalocean" {
  override_during = plan
  mock_resource "digitalocean_reserved_ip" {
    defaults = { ip_address = "203.0.113.30" }
  }
}

mock_provider "tls" {
  override_during = plan
  mock_resource "tls_private_key" {
    defaults = {
      public_key_openssh  = "ssh-ed25519 AAAATESTONLY"
      private_key_openssh = "MOCK-KEY-NOT-A-REAL-PRIVATE-KEY"
    }
  }
}

variables {
  ssh_cidr = "203.0.113.5/32"
}

run "restricted_firewall_and_portable_outputs" {
  command = plan
  assert {
    condition = alltrue([
      for rule in digitalocean_firewall.app.inbound_rule :
      rule.port_range != "22" || rule.source_addresses == toset(["203.0.113.5/32"])
    ])
    error_message = "Only the deployment runner should have SSH access."
  }
  assert {
    condition     = output.ansible_inventory.all.children.app.hosts.full_deploy.ansible_host == "203.0.113.30" && output.ansible_inventory.all.children.app.hosts.full_deploy.ansible_user == "root"
    error_message = "Inventory must point to the reserved IP and correct login user."
  }
  assert {
    condition     = output.ssh_known_hosts == "203.0.113.30 ssh-ed25519 AAAATESTONLY"
    error_message = "The runner must receive the expected SSH host identity."
  }
  assert {
    condition     = yamldecode(digitalocean_droplet.app.user_data).ssh_keys.ed25519_public == trimspace(tls_private_key.host.public_key_openssh)
    error_message = "cloud-init must install the same host identity as known_hosts."
  }
  assert {
    condition     = digitalocean_ssh_key.deploy.public_key == tls_private_key.deploy.public_key_openssh && output.ssh_private_key == tls_private_key.deploy.private_key_openssh
    error_message = "Provisioning and Ansible must use the same generated deployment key."
  }
}

run "reject_world_open_ssh" {
  command = plan
  variables { ssh_cidr = "0.0.0.0/0" }
  expect_failures = [var.ssh_cidr]
}

run "reject_ssh_as_application_port" {
  command = plan
  variables { app_port = 22 }
  expect_failures = [var.app_port]
}
