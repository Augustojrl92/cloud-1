# Declara los proveedores que Terraform necesita y su configuración.
# El proveedor de Google permite trabajar con Google Cloud.
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

# Configuración del proveedor de Google Cloud.
# Los valores se obtienen de las variables declaradas en variables.tf.
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
