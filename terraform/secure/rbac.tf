# =============================================================
# RBAC: mínimo privilegio
# =============================================================
# RBAC controla QUIÉN puede hacer QUÉ y DÓNDE. La regla de oro es el
# mínimo privilegio: cada identidad tiene solo los permisos que necesita.
# Hoy tú eres Propietario (puedes todo); aquí creamos un rol mucho más pequeño.

# Rol personalizado: solo puede LEER la red y los firewalls del lab
resource "azurerm_role_definition" "auditor_red" {
  name        = "lz-auditor-red"
  description = "Solo lectura sobre la red virtual y los NSG del lab. No puede crear, modificar ni borrar nada."

  # Dónde existe el rol: solo en nuestro grupo de recursos
  scope = azurerm_resource_group.rg.id

  permissions {
    # Acciones permitidas. Todas terminan en "read": solo mirar, nunca tocar.
    actions = [
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Network/networkSecurityGroups/read",
      "Microsoft.Network/networkSecurityGroups/securityRules/read",
    ]

    # Acciones prohibidas expresamente: ninguna, porque solo damos lo mínimo
    not_actions = []
  }

  # Dónde se puede ASIGNAR el rol: solo en este grupo de recursos
  assignable_scopes = [
    azurerm_resource_group.rg.id,
  ]
}

# Identidad administrada: una "cuenta de servicio" gratuita dentro de Azure.
# Es a ella a quien damos el rol, sin necesidad de crear usuarios en Entra ID.
resource "azurerm_user_assigned_identity" "auditor" {
  name                = "id-auditor-${local.prefijo}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.etiquetas
}

# Asignación: unimos identidad + rol, limitado al grupo de recursos del lab.
# Así la identidad puede MIRAR la red de este grupo y nada más.
resource "azurerm_role_assignment" "auditor" {
  scope              = azurerm_resource_group.rg.id
  role_definition_id = azurerm_role_definition.auditor_red.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.auditor.principal_id

  # Indicar el tipo evita errores si Azure aún no ha propagado la identidad nueva
  principal_type = "ServicePrincipal"
}
