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
