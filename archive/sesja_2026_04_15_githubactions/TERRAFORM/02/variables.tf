variable "digitalocean_token" {
  description = "This is API key for cloud - this is secret"
  sensitive   = true
}

variable "project_environment" {
  description = "This is Type of environment for project - this is not secret, but we want to validate it"
  type        = string
  default     = "Development"

  validation {
    condition     = contains(["Development", "Production", "Staging"], var.project_environment)
    error_message = "Dozwolone wartosci environment to: Development, Production, Staging."
  }
}
