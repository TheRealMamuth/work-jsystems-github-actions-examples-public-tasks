########################
# Zmienne
########################

variable "name" {
  description = "Nazwa Dropleta"
  type        = string
}

variable "vpc_ip_range" {
  description = "Vpc IP Adrress"
  type        = string
}

variable "do_token" {
  description = "Token API do DigitalOcean"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Region dla Dropleta"
  type        = string
  default     = "fra1"
}

variable "droplet_size" {
  description = "Rozmiar Dropleta"
  type        = string
  default     = "s-2vcpu-2gb"
}

variable "droplet_image" {
  description = "Obraz systemu dla Dropleta"
  type        = string
  # Możesz zmienić np. na nowszy obraz
  default = "ubuntu-22-04-x64"
}

variable "droplets_config_system_user" {
  description = "Nazwa użytkownika systemowego dla Dropletów"
  type        = string
  default     = "jsystems"
}

variable "droplets_config_system_pass" {
  description = "Hasło użytkownika systemowego dla Dropletów"
  type        = string
  default     = "Jsystems2025GitHub"
}

variable "droplets_config_ssh_public_key" {
  description = "Klucz publiczny SSH dla użytkownika systemowego Dropletów"
  type        = string
  default     = ""
}
