# Red privada propia para los recursos de Cloud-1.
resource "google_compute_network" "cloud1_vpc" {
  name                    = "cloud1-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "cloud1_subnet" {
  name          = "cloud1-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.cloud1_vpc.id
}

# IP pública regional reservada para la VM principal.
resource "google_compute_address" "cloud1_static_ip" {
  name   = "cloud1-static-ip"
  region = var.region
}

# Crea una máquina virtual en Google Compute Engine.
resource "google_compute_instance" "cloud1_vm" {

  # Nombre que tendrá la VM dentro de Google Cloud.
  name = "cloud-1-vm"

  # Tipo/tamaño de la máquina.
  # Este valor viene de variables.tf; en nuestro caso será e2-small.
  machine_type = var.machine_type

  # Zona donde se creará la VM.
  # También viene de variables.tf.
  zone = var.zone

  # Permite detener la VM para aplicar cambios de configuración in-place.
  allow_stopping_for_update = true

  # Configuración del disco principal de la máquina.
  boot_disk {
    # Parámetros usados para crear el disco de arranque.
    initialize_params {
      # Imagen del sistema operativo.
      # Usamos Ubuntu 22.04 LTS para la automatización de Cloud-1.
      image = "ubuntu-os-cloud/ubuntu-2204-lts"

      # Tamaño del disco en GB.
      size = 10

      # Tipo de disco persistente de Google Cloud.
      # pd-balanced ofrece un equilibrio entre precio y rendimiento.
      type = "pd-balanced"
    }
  }

  # Configuración de red de la VM.
  network_interface {
    # Conectamos la VM a la subred privada de Cloud-1.
    subnetwork = google_compute_subnetwork.cloud1_subnet.id

    # Este bloque hace que Google asigne una IP pública a la máquina virtual.
    # La necesitaremos para SSH, HTTP y HTTPS.
    access_config {
      nat_ip = google_compute_address.cloud1_static_ip.address
    }
  }

  # Etiqueta de red asociada a la VM.
  # Más adelante podremos usar esta etiqueta en reglas de firewall
  # para indicar que dichas reglas se aplican únicamente a esta máquina.
  tags = ["cloud1"]
}

# Segunda VM para validar despliegue paralelo con Ansible.
resource "google_compute_instance" "cloud1_vm_2" {
  name                      = "cloud-1-vm-2"
  machine_type              = var.machine_type
  zone                      = var.zone
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.cloud1_subnet.id

    access_config {
    }
  }

  tags = ["cloud1"]
}

# Regla de firewall para permitir acceso SSH.
resource "google_compute_firewall" "allow_ssh" {
  name     = "cloud1-allow-ssh"
  network  = google_compute_network.cloud1_vpc.id
  priority = 900

  # Permite conexiones TCP por el puerto 22.
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Permite conexiones desde cualquier IP de Internet.
  # Para el proyecto lo dejamos así de momento.
  source_ranges = ["0.0.0.0/0"]

  # Esta regla solo se aplica a las VMs que tengan la etiqueta "cloud1".
  target_tags = ["cloud1"]
}

# Regla de firewall para permitir tráfico HTTP.
resource "google_compute_firewall" "allow_http" {
  name     = "cloud1-allow-http"
  network  = google_compute_network.cloud1_vpc.id
  priority = 900

  # Puerto estándar HTTP.
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["cloud1"]
}

# Regla de firewall para permitir tráfico HTTPS.
resource "google_compute_firewall" "allow_https" {
  name     = "cloud1-allow-https"
  network  = google_compute_network.cloud1_vpc.id
  priority = 900

  # Puerto estándar HTTPS/TLS.
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["cloud1"]
}

# Deniega cualquier otro tráfico entrante hacia la VM Cloud-1.
# Las reglas de prioridad 900 para SSH, HTTP y HTTPS tienen preferencia.
resource "google_compute_firewall" "deny_other_ingress" {
  name      = "cloud1-deny-other-ingress"
  network   = google_compute_network.cloud1_vpc.id
  direction = "INGRESS"
  priority  = 1000

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["cloud1"]
}
