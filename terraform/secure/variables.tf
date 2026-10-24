# Variables: valores que se pueden cambiar sin tocar el resto del código

variable "location" {
  description = "Región de Azure donde se crean los recursos"
  type        = string
  default     = "germanywestcentral" # si tu suscripción no la permite, se cambia aquí
}

variable "proyecto" {
  description = "Prefijo corto para nombrar los recursos"
  type        = string
  default     = "lz"
}

variable "entorno" {
  description = "Nombre del entorno (lab, pruebas...)"
  type        = string
  default     = "lab"
}

variable "vnet_cidr" {
  description = "Rango de direcciones de toda la red virtual"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "subnet_mgmt_cidr" {
  description = "Rango de la subred de gestión"
  type        = string
  default     = "10.10.1.0/24"
}

variable "subnet_workload_cidr" {
  description = "Rango de la subred de cargas de trabajo"
  type        = string
  default     = "10.10.2.0/24"
}

variable "efecto_politica" {
  description = "Efecto de la política de IPs públicas: Audit (solo avisa), Deny (bloquea) o Disabled (apagada)"
  type        = string
  default     = "Deny" # bloquea: Azure rechaza crear IPs públicas (antes estaba en Audit)

  # Si escribes un valor que no sea uno de los tres, Terraform se queja antes de tocar Azure
  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.efecto_politica)
    error_message = "El efecto debe ser Audit, Deny o Disabled."
  }
}
