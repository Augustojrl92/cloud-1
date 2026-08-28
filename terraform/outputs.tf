# Archivo reservado para las salidas que Terraform mostrará después.
#
# Muestra la IP pública asignada a la VM.
output "public_ip" {
  description = "IP publica de la VM Cloud-1"
  value       = google_compute_instance.cloud1_vm.network_interface[0].access_config[0].nat_ip
}
