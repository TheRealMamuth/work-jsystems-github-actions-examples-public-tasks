variable "digitalocean_token" {
  description = "Token API DigitalOcean odczytywany z lokalnego, ignorowanego pliku terraform.tfvars."
  type        = string
  sensitive   = true
  default     = null
}

variable "name_prefix" {
  description = "Wspólny prefiks nazw zasobów; losowy sufiks zostanie dodany automatycznie."
  type        = string
  default     = "jsystems-dev"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,31}$", var.name_prefix))
    error_message = "Prefiks musi mieć 1-32 znaki, zaczynać się małą literą i zawierać tylko małe litery, cyfry oraz myślniki."
  }
}

variable "project_environment" {
  description = "Środowisko projektu DigitalOcean."
  type        = string
  default     = "Development"
  nullable    = false

  validation {
    condition     = contains(["Development", "Staging", "Production"], var.project_environment)
    error_message = "Dozwolone środowiska: Development, Staging, Production."
  }
}

variable "region" {
  description = "Region DigitalOcean wspólny dla VPC i Dropleta."
  type        = string
  default     = "fra1"
  nullable    = false
}

variable "vpc_ip_range" {
  description = "Opcjonalny CIDR IPv4 VPC; null pozwala DigitalOcean wybrać wolny zakres."
  type        = string
  default     = null

  validation {
    condition     = var.vpc_ip_range == null ? true : can(cidrnetmask(var.vpc_ip_range))
    error_message = "Podaj poprawny CIDR IPv4 lub null. Zakres musi również spełniać wymagania VPC DigitalOcean."
  }
}
