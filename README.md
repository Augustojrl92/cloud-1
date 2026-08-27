# Cloud-1

Proyecto preparado para continuar el desarrollo de Cloud-1 en Google Cloud.

## Estado actual

El objetivo de esta fase fue equiparar el entorno de trabajo y dejar una base
inicial, sin avanzar todavía con la creación de infraestructura.

- Proyecto previsto de Google Cloud: `cloud-1-506415`.
- Región prevista: `us-central1`.
- Zona prevista: `us-central1-c`.
- Terraform instalado: `v1.15.8`.
- Provider de Google instalado: `v7.46.0`.
- `terraform init` ejecutado correctamente.
- `terraform validate` ejecutado correctamente.
- No se ejecutó `terraform plan` ni `terraform apply`.
- No se creó ninguna VM, red, firewall u otro recurso en Google Cloud.
- Ansible y Docker todavía no se han iniciado.

## Estructura

- `terraform/`: configuración inicial de Terraform.
  - `providers.tf`: provider de Google y sus requisitos.
  - `variables.tf`: proyecto, región, zona y tipo de máquina previsto.
  - `main.tf`: reservado para futuros recursos; actualmente está vacío.
  - `outputs.tf`: reservado para futuras salidas de Terraform.
- `ansible/`: reservado para futura configuración de servidores.
- `docker/`: reservado para futura configuración de contenedores.

## GitHub

El proyecto está publicado en el repositorio público:

https://github.com/Augustojrl92/cloud-1

La rama actual es `master`.

## Próximos pasos

Antes de continuar con infraestructura será necesario comprobar la instalación
de Google Cloud CLI, la cuenta autenticada, el proyecto activo y las
Application Default Credentials para Terraform.
