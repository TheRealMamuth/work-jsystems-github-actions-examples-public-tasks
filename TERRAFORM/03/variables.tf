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

variable "own_ssh_public_key" {
  description = "This is your own SSH public key - this is not secret, but we want to validate it"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH8435K6g4GM6CkTTVc+uQ6IAbQolZL/fK2U/ri+ou/L piotrkoska@Piotrs-MacBook-Pro.local"

  validation {
    condition     = can(regex("^ssh-(rsa|ed25519)\\s+[A-Za-z0-9+/]+={0,3}(\\s+.+)?$", var.own_ssh_public_key))
    error_message = "SSH public key musi zaczynac sie od 'ssh-rsa' lub 'ssh-ed25519', a nastepnie zawierac klucz w formacie base64."
  }
}
