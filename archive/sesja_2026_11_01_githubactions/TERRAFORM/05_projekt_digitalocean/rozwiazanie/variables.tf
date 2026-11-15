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
