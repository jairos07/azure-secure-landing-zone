# Arquitectura y decisiones de diseño

Este documento explica **qué se construyó, por qué así y qué alternativas se descartaron**. Está pensado para poder defender cada decisión en una entrevista.

## Resumen

Una red privada en Azure con dos zonas separadas, firewalls de denegar-todo, una política que prohíbe las IPs públicas y un rol de solo lectura. Todo definido con Terraform y revisado con Checkov en cada cambio.

## Recursos desplegados

| Recurso | Nombre | Detalle |
|---|---|---|
| Grupo de recursos | `rg-lz-lab` | Región `germanywestcentral` |
| Red virtual | `vnet-lz-lab` | `10.10.0.0/16` |
| Subred de gestión | `snet-mgmt` | `10.10.1.0/24` |
| Subred de cargas | `snet-workload` | `10.10.2.0/24` |
| NSG de gestión | `nsg-mgmt-lz-lab` | Denegar todo lo entrante |
| NSG de cargas | `nsg-workload-lz-lab` | SSH desde gestión y el resto denegado |
| Asignación de política | `no-ip-publica` | Efecto `Deny`, ámbito del grupo de recursos |
| Rol personalizado | `lz-auditor-red` | Cinco acciones, todas de lectura |
| Identidad administrada | `id-auditor-lz-lab` | Recibe el rol anterior |

Total en Terraform: 8 recursos de red y base, más la política (1) y el RBAC (3).

## Reglas de los NSG

Las reglas se evalúan por prioridad, de menor a mayor número, y se aplica la primera que coincide.

| NSG | Prioridad | Nombre | Acción | Origen | Destino | Puerto |
|---|---|---|---|---|---|---|
| mgmt | 4096 | `denegar-todo-entrante` | Deny | Cualquiera | Cualquiera | Cualquiera |
| workload | 100 | `ssh-solo-desde-gestion` | Allow | `10.10.1.0/24` | `10.10.2.0/24` | 22/TCP |
| workload | 4096 | `denegar-todo-entrante` | Deny | Cualquiera | Cualquiera | Cualquiera |

Azure añade además reglas por defecto con prioridad 65000 o superior. Como la regla de denegar-todo (4096) se evalúa **antes**, pasa por encima de ellas. Eso es intencionado: la regla queda visible en el código en vez de depender de valores por defecto.

