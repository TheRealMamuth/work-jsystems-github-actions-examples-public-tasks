output "resource_name_prefix" {
  description = "Prefiks wraz z losowym sufiksem używany w nazwach wszystkich zasobów."
  value       = local.name
}

output "project" {
  description = "Utworzony projekt DigitalOcean."
  value = {
    id   = digitalocean_project.this.id
    name = digitalocean_project.this.name
  }
}
