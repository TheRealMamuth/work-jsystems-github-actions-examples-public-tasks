resource "digitalocean_project" "this" {
  name        = "${local.name}-project"
  description = "Infrastruktura DigitalOcean zarządzana przez Terraform."
  purpose     = "Operational / Developer tooling"
  environment = var.project_environment
}
