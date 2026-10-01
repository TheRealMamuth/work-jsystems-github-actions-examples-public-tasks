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

output "vpc" {
  description = "VPC i przypisany zakres adresów."
  value = {
    id       = digitalocean_vpc.this.id
    name     = digitalocean_vpc.this.name
    region   = digitalocean_vpc.this.region
    ip_range = digitalocean_vpc.this.ip_range
  }
}
