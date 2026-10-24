# =============================================================
# Azure Policy: prohibir IPs públicas en el grupo de recursos del lab
# =============================================================
# Una política es una regla que la PROPIA Azure impone. Aunque alguien
# intente crear una IP pública (por error o a propósito), Azure la rechaza.
# Usamos una política integrada de Microsoft ("Not allowed resource types")
# en vez de escribir una desde cero.

resource "azurerm_resource_group_policy_assignment" "sin_ip_publica" {
  name         = "no-ip-publica"
  display_name = "Prohibir IPs públicas en el lab"
  description  = "Impide crear recursos de tipo IP pública en el grupo de recursos del proyecto."

  # Ámbito: SOLO este grupo de recursos, no toda la suscripción
  resource_group_id = azurerm_resource_group.rg.id

  # Identificador de la política integrada "Not allowed resource types"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/6c112d4e-5bc7-47ae-a041-ea2d9dccd749"

  # Parámetros de la política (los nombres los hemos leído de tu Azure):
  #  - effect: Audit / Deny / Disabled (viene de la variable efecto_politica)
  #  - listOfResourceTypesNotAllowed: tipos de recurso prohibidos
  parameters = jsonencode({
    effect = {
      value = var.efecto_politica
    }
    listOfResourceTypesNotAllowed = {
      value = ["Microsoft.Network/publicIPAddresses"]
    }
  })
}
