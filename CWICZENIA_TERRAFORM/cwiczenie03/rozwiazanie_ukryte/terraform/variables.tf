variable "vm_name" {
  description = "Nazwa bazowa VM, np. jan-kowalski-vm. Terraform dopisuje stały losowy sufiks."
  type        = string

  validation {
    condition     = length(var.vm_name) >= 3 && length(var.vm_name) <= 50 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.vm_name))
    error_message = "Nazwa VM musi mieć 3–50 znaków: małe litery, cyfry i myślniki; początek to litera, a koniec to litera lub cyfra."
  }
}

variable "vpc_name" {
  description = "Nazwa bazowa prywatnej sieci VPC, np. jan-kowalski-vpc."
  type        = string

  validation {
    condition     = length(var.vpc_name) >= 3 && length(var.vpc_name) <= 50 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.vpc_name))
    error_message = "Nazwa VPC musi mieć 3–50 znaków: małe litery, cyfry i myślniki; początek to litera, a koniec to litera lub cyfra."
  }
}

variable "firewall_name" {
  description = "Nazwa bazowa firewalla, np. jan-kowalski-firewall."
  type        = string

  validation {
    condition     = length(var.firewall_name) >= 3 && length(var.firewall_name) <= 50 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.firewall_name))
    error_message = "Nazwa firewalla musi mieć 3–50 znaków: małe litery, cyfry i myślniki; początek to litera, a koniec to litera lub cyfra."
  }
}

variable "region" {
  description = "Region DigitalOcean wspólny dla VM i VPC."
  type        = string
  default     = "fra1"

  validation {
    condition     = can(regex("^[a-z]{3}[0-9]+$", var.region))
    error_message = "Podaj slug regionu DigitalOcean, np. fra1 albo ams3."
  }
}

variable "vm_image" {
  description = "Slug obrazu systemu operacyjnego VM."
  type        = string
  default     = "ubuntu-24-04-x64"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.vm_image))
    error_message = "Podaj slug obrazu DigitalOcean, np. ubuntu-24-04-x64."
  }
}

variable "vm_size" {
  description = "Slug rozmiaru VM dostępnego w wybranym regionie."
  type        = string
  default     = "s-1vcpu-1gb"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.vm_size))
    error_message = "Podaj slug rozmiaru DigitalOcean, np. s-1vcpu-1gb."
  }
}

variable "vpc_cidr" {
  description = "Niepokrywająca się z innymi VPC prywatna sieć IPv4 z maską /24."
  type        = string
  default     = "10.33.34.0/24"

  validation {
    condition = can(cidrnetmask(var.vpc_cidr)) && can(regex("/24$", var.vpc_cidr)) && can(
      regex("^(10\\.|192\\.168\\.|172\\.(1[6-9]|2[0-9]|3[01])\\.)", var.vpc_cidr)
    ) && try(cidrhost(var.vpc_cidr, 0) == split("/", var.vpc_cidr)[0], false)
    error_message = "Podaj adres prywatnej sieci IPv4 RFC1918 z maską /24, np. 10.33.34.0/24; adres hosta ani publiczna sieć nie są dozwolone."
  }
}

variable "ssh_allowed_cidr" {
  description = "Publiczny adres IPv4 self-hosted runnera z maską /32; tylko ten host otrzyma dostęp SSH do VM."
  type        = string

  validation {
    condition = can(cidrnetmask(var.ssh_allowed_cidr)) && try(
      tonumber(split("/", var.ssh_allowed_cidr)[1]) == 32 &&
      cidrhost(var.ssh_allowed_cidr, 0) == split("/", var.ssh_allowed_cidr)[0],
      false
    )
    error_message = "Podaj jeden publiczny adres IPv4 z maską /32, np. 203.0.113.10/32; nie używaj 0.0.0.0/0."
  }
}

variable "ssh_private_key_path" {
  description = "Ścieżka pliku klucza SSH; pipeline przekazuje bezwzględną ścieżkę w trwałym katalogu stanu, poza checkoutem."
  type        = string
  default     = ".keys/id_ed25519"

  validation {
    condition     = length(trimspace(var.ssh_private_key_path)) > 0 && !can(regex("[[:cntrl:]]", var.ssh_private_key_path))
    error_message = "Podaj niepustą ścieżkę pliku klucza SSH, bez znaków sterujących i nowych linii."
  }
}

variable "image_reference" {
  description = "Gotowy obraz aplikacji przypięty niezmiennym digestem SHA256. Terraform nie buduje obrazu."
  type        = string
  default     = "piotrskoska/python_pogoda@sha256:ac30d995f5ca10e4c5db5c44d526398c435270ba1194c5987642f7179a224638"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._/-]*@sha256:[a-f0-9]{64}$", var.image_reference))
    error_message = "Podaj obraz w postaci login/obraz@sha256:<64 znaki hex>; nie używaj ruchomego tagu."
  }
}

variable "container_name" {
  description = "Stała nazwa kontenera aplikacji na VM; ponowny deploy zastępuje wyłącznie kontener o tej nazwie."
  type        = string
  default     = "cw03-pogoda"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_.-]{0,62}$", var.container_name))
    error_message = "Nazwa kontenera: 1–63 małe litery, cyfry, myślniki, podkreślenia lub kropki; początek to litera lub cyfra."
  }
}

variable "deployment_revision" {
  description = "Niepoufna rewizja deploya; zwiększ np. z 1 na 2 po zmianie sekretu API lub danych logowania Docker Hub."
  type        = string
  default     = "1"

  validation {
    condition     = length(trimspace(var.deployment_revision)) > 0 && length(var.deployment_revision) <= 64 && !can(regex("[[:cntrl:]]", var.deployment_revision))
    error_message = "Podaj niepustą rewizję deploya o długości do 64 znaków, bez nowych linii i znaków sterujących."
  }
}

variable "openweather_api_key" {
  description = "Klucz OpenWeatherMap przekazany przez TF_VAR_openweather_api_key wyłącznie do provisionera; pomijany przy destroy."
  type        = string
  default     = null
  sensitive   = true
  ephemeral   = true
}

variable "dockerhub_username" {
  description = "Opcjonalny publiczny login Docker Hub; potrzebny tylko wraz z tokenem do uwierzytelnionego pobrania obrazu."
  type        = string
  default     = ""

  validation {
    condition     = var.dockerhub_username == "" || can(regex("^[a-z0-9][a-z0-9_-]*$", var.dockerhub_username))
    error_message = "Podaj poprawny login Docker Hub małymi literami albo pozostaw pustą wartość dla pobrania publicznego."
  }
}

variable "dockerhub_token" {
  description = "Opcjonalny token Docker Hub przekazany przez TF_VAR_dockerhub_token tylko do provisionera."
  type        = string
  default     = ""
  sensitive   = true
  ephemeral   = true
}
