# Muestra las IPs públicas de las VMs.
output "public_ip" {
  description = "IP publica de la VM Cloud-1"
  value       = google_compute_instance.cloud1_vm.network_interface[0].access_config[0].nat_ip
}

output "public_ip_2" {
  description = "IP publica de la segunda VM Cloud-1"
  value       = google_compute_instance.cloud1_vm_2.network_interface[0].access_config[0].nat_ip
}
