variable "environment" {
  description = "Środowisko DigitalOcean. Test pozostaje na self-hosted runnerze."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Dozwolone środowiska DigitalOcean: dev oraz prod."
  }
}

variable "student_name" {
  description = "Imię i nazwisko uczestnika w formacie jan-kowalski, bez polskich znaków."
  type        = string

  validation {
    condition     = length(var.student_name) >= 3 && length(var.student_name) <= 40 && can(regex("^[a-z][a-z0-9]*(-[a-z0-9]+)+$", var.student_name))
    error_message = "Podaj 3–40 znaków w formacie jan-kowalski: małe litery ASCII, cyfry i pojedyncze myślniki pomiędzy członami."
  }
}

variable "region" {
  description = "Slug regionu DigitalOcean dostępnego na koncie."
  type        = string
  default     = "fra1"
}

variable "droplet_size" {
  description = "Rozmiar Dropleta x64 dostępny w wybranym regionie."
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "ssh_allowed_cidr" {
  description = "Publiczny adres IPv4 self-hosted runnera z maską /32."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.ssh_allowed_cidr)) && try(tonumber(split("/", var.ssh_allowed_cidr)[1]) == 32, false)
    error_message = "Podaj pojedynczy publiczny IPv4 runnera z maską /32, np. 203.0.113.10/32."
  }
}

variable "dockerhub_username" {
  description = "Login Docker Hub używany podczas pobierania opublikowanego obrazu."
  type        = string
  default     = "piotrskoska"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_-]*$", var.dockerhub_username))
    error_message = "Podaj prawidłowy login Docker Hub, małymi literami."
  }
}

variable "dockerhub_token" {
  description = "Token Docker Hub przekazywany tylko do provisionera przez TF_VAR_dockerhub_token."
  type        = string
  default     = null
  sensitive   = true
  ephemeral   = true
}

variable "openweather_api_key" {
  description = "Klucz API przekazywany tylko do docker run przez TF_VAR_openweather_api_key."
  type        = string
  default     = null
  sensitive   = true
  ephemeral   = true
}

variable "image_reference" {
  description = "Opublikowany i przetestowany obraz repozytorium@sha256:digest. Przy destroy może być pominięty."
  type        = string
  default     = null

  validation {
    condition     = var.image_reference == null ? true : can(regex("^[a-z0-9][a-z0-9._/-]*@sha256:[a-f0-9]{64}$", var.image_reference))
    error_message = "Wymagany jest obraz przypięty digestem, np. piotrskoska/python_pogoda@sha256:<64 znaki hex>."
  }
}

variable "deployment_id" {
  description = "ID przebiegu GitHub Actions; zmiana wymusza ponowne uruchomienie deploya aplikacji."
  type        = string
  default     = "manual"
}

variable "ssh_host_key" {
  description = "Opcjonalny zaufany publiczny klucz hosta SSH lub CA. Null oznacza brak weryfikacji klucza serwera przez provisioner."
  type        = string
  default     = null
}
