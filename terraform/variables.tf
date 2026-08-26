# Variables centralizadas del proyecto para evitar repetir valores.

# ID único del proyecto de Google Cloud.
variable "project_id" {
  description = "ID del proyecto de Google Cloud"
  type        = string
  default     = "cloud-1-506415"
}

# Región principal prevista para los recursos.
variable "region" {
  description = "Region de Google Cloud"
  type        = string
  default     = "us-central1"
}

# Zona concreta dentro de la región.
variable "zone" {
  description = "Zona de Google Cloud"
  type        = string
  default     = "us-central1-c"
}

# Tipo de máquina previsto para futuras VM.
# Declarar esta variable no crea ninguna máquina virtual.
variable "machine_type" {
  description = "Tipo de maquina para Cloud-1"
  type        = string
  default     = "e2-small"
}
