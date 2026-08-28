# Cloud-1

Cloud-1 automatiza el camino desde infraestructura en Google Cloud hasta una
VM preparada para ejecutar una futura aplicación web en contenedores.

~~~mermaid
flowchart LR
    Repo[Repositorio local] --> TF[Terraform]
    TF --> GCP[Google Cloud]
    GCP --> VM[Compute Engine VM]
    VM --> SSH[SSH]
    SSH --> ANS[Ansible]
    ANS --> Docker[Docker Engine y Compose]
    Docker -. fase futura .-> App[Nginx · WordPress · MariaDB · phpMyAdmin]
~~~

## Vista rápida

| Capa | Responsabilidad | Estado |
|---|---|---|
| Terraform | Aprovisionar VM, red y firewall | Implementado en código |
| Ansible | Configurar el sistema operativo | Rol Docker implementado |
| Docker | Instalar el motor y Compose | Implementado en el rol |
| Deployment | Desplegar la aplicación | Pendiente |

Terraform aplica Infrastructure as Code: la infraestructura se expresa en
archivos versionables, revisables y repetibles. Ansible aplica Configuration
Management: declara cómo debe quedar el servidor. Docker Compose será la capa
que describa la aplicación. Esta separación evita mezclar cloud, sistema
operativo y servicios.

## Arquitectura actual y prevista

~~~mermaid
flowchart TB
    Internet((Internet))
    Internet -->|22 TCP| SSH[SSH]
    Internet -->|80 TCP| HTTP[HTTP]
    Internet -->|443 TCP| HTTPS[HTTPS]
    SSH --> VM[cloud-1-vm<br/>Ubuntu 22.04]
    HTTP --> VM
    HTTPS --> VM
    TF[Terraform] --> VM
    TF --> FW[Firewall con tag cloud1]
~~~

La configuración declara una VM, una IP pública efímera y reglas para 22, 80
y 443. HTTP y HTTPS están abiertos en previsión de la aplicación; todavía no
existen Nginx ni servicios web en el repositorio.

~~~mermaid
flowchart LR
    Internet((Internet)) -->|80 / 443| Nginx[Nginx]
    Nginx --> WordPress[WordPress]
    WordPress --> DB[(MariaDB)]
    phpMyAdmin[phpMyAdmin] --> DB
~~~

Nginx, WordPress, MariaDB y phpMyAdmin son objetivos de deployment. MariaDB
debe comunicarse internamente con sus consumidores, nunca exponerse a Internet.

## Estructura real del repositorio

~~~text
cloud-1/
├── .gitignore
├── README.md
├── terraform/
│   ├── providers.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── .terraform.lock.hcl
├── ansible/
│   ├── inventory/hosts.ini
│   ├── playbook.yml
│   └── roles/
│       ├── docker/tasks/main.yml
│       ├── deployment/tasks/main.yml
│       └── security/tasks/main.yml
└── docker/
~~~

Los archivos deployment/tasks/main.yml y security/tasks/main.yml existen pero
están vacíos. La carpeta docker existe pero no contiene todavía un archivo
Compose ni servicios.

### Terraform

#### terraform/providers.tf

Declara el provider hashicorp/google con versión ~> 7.0. El provider usa las
variables project_id, region y zone; separarlo de los recursos mantiene la
configuración de Google Cloud aislada de la infraestructura.

#### terraform/variables.tf

Centraliza valores reutilizables:

| Variable | Valor por defecto | Uso |
|---|---|---|
| project_id | cloud-1-506415 | Proyecto de Google Cloud |
| region | us-central1 | Región prevista |
| zone | us-central1-c | Zona de recursos zonales |
| machine_type | e2-small | Tamaño de la VM |

Cada bloque define description, type y default. Usar var.machine_type evita
repetir valores y facilita cambios futuros.

#### terraform/main.tf

Define una instancia google_compute_instance.cloud1_vm y tres recursos de
firewall. google_compute_instance.cloud1_vm es la dirección lógica de
Terraform; cloud-1-vm es el nombre real dentro de Google Cloud.

La VM consume machine_type y zone desde variables. El disco de arranque usa
Ubuntu 22.04 LTS, 10 GB y pd-balanced. network_interface usa la red default y
access_config solicita IP pública. El tag cloud1 conecta la VM con las reglas.

Las reglas allow_ssh, allow_http y allow_https permiten TCP 22, 80 y 443.
Usan la red default, source_ranges 0.0.0.0/0 y target_tags cloud1. La base de
datos no requiere regla pública: debe quedar en la red interna de Docker.

#### terraform/outputs.tf

El output public_ip devuelve la IP pública:

~~~hcl
google_compute_instance.cloud1_vm.network_interface[0].access_config[0].nat_ip
~~~

La expresión recorre el recurso, primera interfaz de red, primera configuración
de acceso y finalmente nat_ip.

#### .terraform y .terraform.lock.hcl

terraform init descarga providers en .terraform; es contenido generado y se
ignora. .terraform.lock.hcl fija versiones verificadas y sí debe versionarse.

### Ansible

#### ansible/inventory/hosts.ini

Define el grupo cloud, el alias cloud1, el host real, el usuario SSH y la ruta
de clave privada. El grupo es lógico; el alias no tiene que coincidir con el
hostname. No se reproduce aquí la IP ni una ruta concreta de clave para evitar
exponer datos de conexión. Como la IP es efímera, el inventory puede requerir
actualización después de detener y arrancar la VM.

#### ansible/playbook.yml

El playbook usa hosts: cloud, become: true y el rol docker. become eleva
privilegios para instalar paquetes, modificar /etc y gestionar servicios. La
prueba temporal whoami devolvió root; no forma parte del playbook actual.

#### ansible/roles/docker/tasks/main.yml

Automatiza Docker con módulos declarativos:

| Tarea | Módulo | Motivo |
|---|---|---|
| Actualizar caché | apt | Respeta cache_valid_time |
| Instalar dependencias | apt | Garantiza paquetes presentes |
| Crear keyring | file | Garantiza directorio y permisos |
| Descargar clave | get_url | Obtiene clave GPG oficial |
| Añadir repositorio | apt_repository | Gestiona APT sin editar archivos manualmente |
| Instalar Docker | apt | Garantiza componentes presentes |
| Activar servicio | service | Garantiza inicio y arranque |

Los módulos son preferibles a shell porque entienden el estado deseado y
favorecen la idempotencia.

#### Roles deployment y security

Existen como estructura organizativa, pero no tienen tareas aún. deployment
desplegará la aplicación; security se reserva para endurecimiento futuro.
Separar roles mejora organización, reutilización, mantenibilidad y
responsabilidades claras frente a un playbook con muchas tareas mezcladas.

## Bitácora técnica

### Paso 1 — Diseñar la automatización

**Objetivo.** Reemplazar la creación y configuración manual por un proceso
repetible.

**Qué hicimos.** Se separaron Terraform, Ansible y Docker Compose. Terraform
crea recursos cloud; Ansible configura Ubuntu; Compose ejecutará la aplicación.

**Concepto aprendido.** Estado deseado: se declara qué debe existir, no una
secuencia manual de clics.

### Paso 2 — Autenticar Google Cloud e inicializar Terraform

**Objetivo.** Permitir al provider de Google comunicarse con las APIs.

**Comandos utilizados.**

~~~bash
gcloud auth login
gcloud config set project cloud-1-506415
gcloud auth application-default login
gcloud auth application-default set-quota-project cloud-1-506415
terraform init
terraform validate
~~~

**Resultado.** gcloud auth login autentica la CLI. Application Default
Credentials, o ADC, son las credenciales que el provider puede descubrir sin
guardarlas en Git. El quota project asigna cuotas de llamadas a APIs.

**Qué validó.** terraform validate verifica sintaxis y bloques, pero no crea
recursos ni consulta cambios remotos.

### Paso 3 — Planificar y aplicar la infraestructura

**Objetivo.** Revisar la infraestructura antes de crearla.

~~~bash
terraform plan
terraform apply
~~~

**Resultado registrado.**

~~~text
Plan: 4 to add, 0 to change, 0 to destroy
~~~

Plan compara estado deseado contra estado actual conocido por Terraform. Apply
crea los recursos reales. Terraform State registra esa relación; puede incluir
datos sensibles, por lo que *.tfstate está ignorado y no se versiona.

### Paso 4 — Resolver SSH entre Windows, WSL y la VM

**Objetivo.** Permitir que Ansible gestione la VM desde WSL.

**Problema.** Se obtuvo Permission denied (publickey): gcloud había generado
la clave en Windows y WSL tiene su propio entorno ~/.ssh.

**Solución.** Se reutilizó la clave en WSL y se ejecutó:

~~~bash
chmod 600 ~/.ssh/google_compute_engine
~~~

600 significa que solo el propietario puede leer y escribir. SSH rechaza
claves con permisos abiertos para proteger credenciales privadas.

### Paso 5 — Verificar Ansible

**Objetivo.** Confirmar SSH, Python remoto y ejecución de módulos.

~~~bash
ansible all -i inventory/hosts.ini -m ping
~~~

**Resultado esperado.**

~~~text
cloud1 | SUCCESS => {"changed": false, "ping": "pong"}
~~~

No es un ping ICMP: comprueba Ansible → SSH → Python remoto → módulo → pong.
La conexión SSH permitió avanzar al playbook y al rol Docker.

### Paso 6 — Instalar Docker de forma declarativa

**Objetivo.** Preparar Ubuntu para contenedores y futuros servicios.

La cadena seguida fue:

~~~text
APT → dependencias → /etc/apt/keyrings → clave GPG → repositorio Docker
    → docker-ce → Docker Engine
~~~

La clave GPG verifica origen e integridad de los paquetes. La variable
{{ ansible_distribution_release }} es un Ansible Fact recopilado del host; en
Ubuntu 22.04 corresponde a jammy.

Se instalan docker-ce (Engine), docker-ce-cli (cliente), containerd.io
(runtime), docker-buildx-plugin (construcción avanzada) y
docker-compose-plugin (orquestación de varios servicios). state: started
significa que Docker funciona ahora; enabled: true que arrancará tras reboot.

**Verificación registrada.**

~~~text
Docker version 29.7.2
Docker Compose version v5.5.0
~~~

### Paso 7 — Comprobar idempotencia

**Objetivo.** Poder repetir automatización sin cambios innecesarios.

Ansible declara Docker debe estar instalado, en lugar de ejecutar de forma
imperativa un comando apt install cada vez. Una segunda ejecución debe tender a:

~~~text
changed=0
failed=0
~~~

Un comando ad-hoc con command para consultar versión puede marcar CHANGED:
command no sabe si hubo modificación real. Los módulos declarativos sí conocen
el estado objetivo.

## Cómo reproducir lo implementado

1. Instalar Terraform y Google Cloud CLI.
2. Autenticar gcloud y configurar ADC.
3. Ejecutar terraform init y terraform validate en terraform/.
4. Revisar terraform plan y aplicar solo tras confirmación.
5. Obtener terraform output public_ip.
6. Actualizar el inventory con IP actual y datos SSH.
7. Ejecutar:

~~~bash
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbook.yml
~~~

8. Verificar Docker y Compose remotamente.

No existen pasos de Nginx, WordPress, MariaDB o phpMyAdmin porque todavía no
están implementados.

## Seguridad

El .gitignore real excluye .terraform/, *.tfstate, archivos crash, *.tfvars,
application_default_credentials.json, *.key y *.pem.

No deben versionarse claves SSH privadas, credenciales de Google o ADC, tokens,
Terraform State, contraseñas de base de datos, secretos de WordPress ni
variables sensibles. El state puede contener atributos privados aunque el
código no los muestre.

## Estado y próximos pasos

| Elemento | Estado |
|---|---|
| Terraform, provider y variables | IMPLEMENTADO |
| VM, red por defecto y firewall declarados | IMPLEMENTADO |
| Output de IP pública | IMPLEMENTADO |
| Inventory, playbook y rol Docker | IMPLEMENTADO |
| Role deployment | EN DESARROLLO: archivo vacío |
| Role security | PENDIENTE: archivo vacío |
| docker-compose.yml, Nginx, WordPress, MariaDB, phpMyAdmin y volúmenes | PENDIENTE |
| TLS, IP estática, VPC propia, backups, monitorización y CI/CD | MEJORA FUTURA |

El siguiente paso exacto es ansible/roles/deployment/tasks/main.yml: crear
/opt/cloud-1 mediante Ansible y avanzar después hacia docker-compose.yml.

## Conceptos aprendidos

- IaC y desired state: infraestructura declarada y reproducible.
- Provider y State: conexión a APIs y relación entre código y recursos reales.
- ADC: autenticación del provider sin secretos en Git.
- Compute Engine, firewall y tags: VM y acceso de red controlado.
- SSH, claves y WSL: administración remota desde Linux local.
- Inventory, playbook, roles, facts y become: estructura de Ansible.
- Idempotencia: ejecuciones repetibles sin cambios innecesarios.
- Docker Engine, Compose y container runtime: base de la aplicación futura.

## Repositorio

Repositorio público: https://github.com/Augustojrl92/cloud-1

Rama actual: master
