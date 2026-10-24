# Azure Secure Landing Zone

[![Checkov](https://github.com/jairos07/azure-secure-landing-zone/actions/workflows/checkov.yml/badge.svg)](https://github.com/jairos07/azure-secure-landing-zone/actions/workflows/checkov.yml)
![Terraform](https://img.shields.io/badge/Terraform-1.17-7B42BC?logo=terraform)
![Azure](https://img.shields.io/badge/Azure-free%20tier-0078D4)
![Checkov](https://img.shields.io/badge/Checkov-3.3.30-blue)
![IaC](https://img.shields.io/badge/IaC-DevSecOps-success)

Landing zone segura en Azure definida como código. Una red segmentada sin IPs públicas, una política que **impone** esa norma desde la propia Azure, un rol de mínimo privilegio y un pipeline que revisa el Terraform en cada cambio. Todo dentro del free tier de una suscripción *Azure for Students*.

> Proyecto de portfolio orientado a Cloud Security y Network Security. Toda la documentación está en español.

## Qué es

Un entorno pequeño en Azure construido con Terraform en el que la seguridad no se "pone después", sino que forma parte del código:

1. El código se **revisa automáticamente** antes de desplegar (Checkov en GitHub Actions).
2. La red nace **segmentada** y con todo denegado por defecto.
3. Una **política de Azure** impide crear IPs públicas, aunque alguien lo intente a mano.
4. Los permisos siguen el **mínimo privilegio**: un rol personalizado de solo lectura.
5. El repositorio está protegido para que **nunca se suban estados ni secretos**.

## Qué demuestra

| Habilidad | Evidencia en el repo |
|---|---|
| Infraestructura como código | `terraform/secure/` (red, política y RBAC) |
| DevSecOps / shift-left | `.github/workflows/checkov.yml` |
| Segmentación de red | Dos subredes con NSG de denegar-todo |
| Guardarraíles preventivos | Política en modo `Deny` y prueba de bloqueo real |
| Mínimo privilegio | Rol `lz-auditor-red` e identidad administrada |
| Higiene del repositorio | `.gitignore` comprobado antes de crear estado |
| Resolución de problemas | [`docs/hallazgos.md`](docs/hallazgos.md) |

## Arquitectura

```
 GitHub (jairos07/azure-secure-landing-zone)
   |  push --> GitHub Actions --> Checkov (escaneo del Terraform)
   |
 Equipo local: Terraform + Azure CLI
   |  az login
   v
 AZURE  (suscripcion Azure for Students, region germanywestcentral)
 +------------------------------------------------------------------+
 |  Azure Policy (ambito: grupo de recursos rg-lz-lab)              |
 |    - Prohibir IPs publicas ............................ [Deny]   |
 |                                                                  |
 |  rg-lz-lab                                                       |
 |  +------------------------------------------------------------+  |
 |  |  vnet-lz-lab  10.10.0.0/16        (sin ninguna IP publica) |  |
 |  |                                                            |  |
 |  |   snet-mgmt      10.10.1.0/24                              |  |
 |  |     +-- nsg-mgmt-lz-lab: denegar todo lo entrante          |  |
 |  |                                                            |  |
 |  |   snet-workload  10.10.2.0/24                              |  |
 |  |     +-- nsg-workload-lz-lab:                               |  |
 |  |           SSH (22) solo desde 10.10.1.0/24                 |  |
 |  |           todo lo demas entrante: denegado                 |  |
 |  +------------------------------------------------------------+  |
 |                                                                  |
 |  id-auditor-lz-lab (identidad administrada)                      |
 |    +-- rol lz-auditor-red (solo lectura) en rg-lz-lab            |
 +------------------------------------------------------------------+
```

## Controles de seguridad

| Control | Riesgo que reduce | Cómo se implementa | Fichero |
|---|---|---|---|
| Sin IPs públicas | Superficie de ataque expuesta a Internet | Ningún recurso de tipo IP pública en el diseño | `network.tf` |
| Política `Deny` de IPs públicas | Que alguien cree una a mano o por error | Política integrada *Not allowed resource types* asignada al grupo de recursos | `policy.tf` |
| NSG de denegar-todo | Entrada de tráfico no previsto | Regla explícita de prioridad 4096 en ambas subredes | `network.tf` |
| SSH solo desde gestión | Fuerza bruta y movimiento lateral | Regla 100: puerto 22 únicamente desde `10.10.1.0/24` | `network.tf` |
| Segmentación | Que una zona comprometida llegue a la otra | Dos subredes con su propio NSG asociado | `network.tf` |
| Mínimo privilegio | Permisos excesivos | Rol con cinco acciones, todas `read`, limitado al grupo de recursos | `rbac.tf` |
| Escaneo del IaC | Malas configuraciones antes de desplegar | Checkov en cada `push` y `pull request`, con permisos de solo lectura | `.github/workflows/checkov.yml` |
| Protección del repo | Filtrar estado, variables o claves | `.gitignore` con `*.tfstate`, `*.tfvars` y `.terraform/` | `.gitignore` |
| Etiquetado | Trazabilidad y control de costes | `proyecto`, `entorno` y `gestionado_por` en todos los recursos | `network.tf` |

## Evidencias

Las capturas están en [`img/config/`](img/config/) y los identificadores de la suscripción están tapados.

**1. Escaneo local con Checkov** sobre el código de red: 12 comprobaciones pasadas y 0 fallos.

![Checkov local](img/config/01-checkov-local.png)

**2. Pipeline de GitHub Actions** ejecutando el mismo escaneo en cada cambio.

![GitHub Actions](img/config/02-github-actions-verde.png)

**3. Validación de Terraform** (`init` y `validate`).

![Terraform validate](img/config/03-terraform-validate.png)

**4. Despliegue final** en una región permitida por la suscripción: 8 recursos creados y 1 reemplazado.

![Apply final](img/config/05-apply-final.png)

**5. Grupo de recursos desplegado** con la red y los dos NSG, todo etiquetado.

![Grupo de recursos](img/config/06-portal-grupo-recursos.png)

**6. Reglas del NSG de cargas de trabajo**: SSH solo desde la subred de gestión y el resto denegado.

![NSG workload](img/config/08-portal-nsg-workload.png)

**7. Rol personalizado y su asignación**: cinco acciones de lectura y una asignación a una identidad administrada.

![RBAC](img/config/09-rbac-rol-y-asignacion.png)

**8. La política bloquea la creación de una IP pública.** Salida real del intento, con el identificador de suscripción sustituido:

```text
(RequestDisallowedByPolicy) Resource 'pip-prueba-bloqueo' was disallowed by policy.
Policy identifiers: '[{"policyAssignment":{"name":"Prohibir IPs públicas en el lab",
"id":"/subscriptions/<ID-DE-SUSCRIPCION>/resourceGroups/rg-lz-lab/providers/
Microsoft.Authorization/policyAssignments/no-ip-publica"},
"policyDefinition":{"name":"Not allowed resource types", ...
Code: RequestDisallowedByPolicy
```

El intento se repitió dos veces con el mismo resultado y no se creó ninguna IP.

## Estructura del repositorio

```
azure-secure-landing-zone/
├── README.md
├── .gitignore
├── .github/workflows/
│   └── checkov.yml        # escaneo de seguridad del IaC
├── terraform/secure/
│   ├── providers.tf       # versiones de Terraform y proveedor
│   ├── variables.tf       # región, rangos de red y efecto de la política
│   ├── network.tf         # grupo de recursos, red, subredes y NSG
│   ├── policy.tf          # asignación de Azure Policy
│   └── rbac.tf            # rol personalizado, identidad y asignación
├── docs/
│   ├── arquitectura.md    # decisiones de diseño
│   ├── hallazgos.md       # problemas encontrados y cómo se resolvieron
│   └── limitaciones.md    # qué no cubre y qué falta por verificar
├── evidence/
└── img/config/            # capturas
```

## Requisitos

| Herramienta | Versión usada |
|---|---|
| Terraform | 1.17.0 (mínimo exigido en el código: 1.5.0) |
| Proveedor `azurerm` | 4.81.0 |
| Azure CLI | 2.91.0 |
| Checkov | 3.3.30 |
| Sistema | Ubuntu 24.04 |

## Cómo reproducirlo

```bash
git clone https://github.com/jairos07/azure-secure-landing-zone.git
cd azure-secure-landing-zone/terraform/secure

az login
# El ID de suscripción NO se guarda en ningún fichero: solo en esta terminal
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

terraform init
terraform plan
terraform apply
```

Notas:

- La región por defecto es `germanywestcentral`. Si tu suscripción restringe regiones, cámbiala con `-var location=<región>`. Las regiones permitidas se consultan con `az policy assignment list`.
- La política se despliega en modo `Deny`. Para probar solo avisando: `-var efecto_politica=Audit`.
- Las políticas pueden tardar entre 15 y 30 minutos en aplicarse tras asignarlas.
- Para borrar todo: `terraform destroy`. Elimina también la política, el rol y la identidad.
- Se necesitan permisos de **Propietario** sobre la suscripción para asignar la política y crear el rol.

## Coste y free tier

El diseño evita lo que tiene coste: no hay máquinas virtuales, ni IPs públicas, ni espacios de trabajo de Log Analytics, ni cuentas de almacenamiento.

| Pieza | Coste esperado | Estado |
|---|---|---|
| Grupo de recursos, red virtual, subredes y NSG | 0, según mi conocimiento de los precios de Azure | **Pendiente de comprobar en Cost Management** |
| Azure Policy y RBAC | 0 | **Pendiente de comprobar** |
| Identidad administrada | 0 | **Pendiente de comprobar** |
| Terraform, Checkov y GitHub Actions | 0 (repositorio público) | Verificado |

Los datos de Cost Management tardan hasta 24 horas en aparecer, por eso esta comprobación está pendiente y no se da por hecha.

## Estado del proyecto

| Bloque | Estado |
|---|---|
| Red segmentada con NSG | Hecho y desplegado |
| Escaneo con Checkov en local y CI | Hecho (ver nota en limitaciones) |
| Azure Policy en modo `Deny` con prueba de bloqueo | Hecho |
| RBAC de mínimo privilegio | Hecho |
| Comprobación de coste | Pendiente |
| Secure score de Defender for Cloud | Pendiente |
| Endurecer la salida a Internet de las subredes | Pendiente |

El detalle de lo que falta está en [`docs/limitaciones.md`](docs/limitaciones.md).

## Documentación

| Documento | Contenido |
|---|---|
| [`docs/arquitectura.md`](docs/arquitectura.md) | Decisiones de diseño y alternativas descartadas |
| [`docs/hallazgos.md`](docs/hallazgos.md) | Problemas reales encontrados y su solución |
| [`docs/limitaciones.md`](docs/limitaciones.md) | Lo que el proyecto no cubre y lo que falta por verificar |

## Lo aprendido

- Un escaneo con 0 fallos no significa "seguro": solo revisa lo que existe en el código y las reglas que conoce.
- Las suscripciones educativas restringen regiones mediante políticas, y `terraform plan` no lo detecta porque solo simula.
- El `.gitignore` hay que **comprobarlo**, no darlo por supuesto: aquí faltaba y se detectó antes de crear ningún estado.
- Una política en modo `Deny` es la diferencia entre *seguir* una buena práctica e *imponerla*.
- El rol de Propietario en una suscripción no convierte a nadie en administrador del directorio de identidades.
