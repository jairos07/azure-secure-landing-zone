# Valores calculados que se reutilizan en varios recursos
locals {
  prefijo = "${var.proyecto}-${var.entorno}"

  # Etiquetas: sirven para saber de qué proyecto es cada recurso y quién lo gestiona
  etiquetas = {
    proyecto       = "azure-secure-landing-zone"
    entorno        = var.entorno
    gestionado_por = "terraform"
  }
}

# Grupo de recursos: la "carpeta" de Azure donde vive todo lo demás
resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.prefijo}"
  location = var.location
  tags     = local.etiquetas
}

# Red virtual: la red privada. Ninguna parte de ella tiene IP pública
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.prefijo}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_cidr
  tags                = local.etiquetas
}

# Subred de gestión: desde aquí se administra el resto
resource "azurerm_subnet" "mgmt" {
  name                 = "snet-mgmt"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_mgmt_cidr]
}

# Subred de cargas de trabajo: donde irán las máquinas del proyecto
resource "azurerm_subnet" "workload" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_workload_cidr]
}

# ---------- Firewall de la subred de gestión: no entra nada ----------
resource "azurerm_network_security_group" "mgmt" {
  name                = "nsg-mgmt-${local.prefijo}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.etiquetas

  # Denegamos TODO el tráfico entrante de forma explícita.
  # Prioridad 4096 = la última regla que se evalúa.
  security_rule {
    name                       = "denegar-todo-entrante"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ---------- Firewall de la subred de cargas: solo SSH desde gestión ----------
resource "azurerm_network_security_group" "workload" {
  name                = "nsg-workload-${local.prefijo}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.etiquetas

  # Regla 1: SSH (puerto 22) permitido SOLO desde la subred de gestión
  security_rule {
    name                       = "ssh-solo-desde-gestion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.subnet_mgmt_cidr
    destination_address_prefix = var.subnet_workload_cidr
  }

  # Regla 2: todo lo demás que intente entrar, denegado
  security_rule {
    name                       = "denegar-todo-entrante"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ---------- Asociamos cada firewall a su subred ----------
# Sin esto las reglas existen, pero no se aplican a nada.
resource "azurerm_subnet_network_security_group_association" "mgmt" {
  subnet_id                 = azurerm_subnet.mgmt.id
  network_security_group_id = azurerm_network_security_group.mgmt.id
}

resource "azurerm_subnet_network_security_group_association" "workload" {
  subnet_id                 = azurerm_subnet.workload.id
  network_security_group_id = azurerm_network_security_group.workload.id
}
