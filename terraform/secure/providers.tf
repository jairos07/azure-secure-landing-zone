# Versión mínima de Terraform y proveedor de Azure
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# El ID de suscripción NO se escribe aquí, para no subirlo al repo.
# Cuando despleguemos se pasa con la variable de entorno ARM_SUBSCRIPTION_ID.
provider "azurerm" {
  features {}
}
