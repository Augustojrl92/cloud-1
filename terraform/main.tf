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
    # Utilizamos por ahora la red "default" de Google Cloud.
    network = "default"

    # Este bloque hace que Google asigne una IP pública a la máquina virtual.
    # La necesitaremos para SSH, HTTP y HTTPS.
    access_config {
    }
  }

  # Etiqueta de red asociada a la VM.
  # Más adelante podremos usar esta etiqueta en reglas de firewall
  # para indicar que dichas reglas se aplican únicamente a esta máquina.
  tags = ["cloud1"]
}

# Regla de firewall para permitir acceso SSH.
resource "google_compute_firewall" "allow_ssh" {
  name    = "cloud1-allow-ssh"
  network = "default"

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
  name    = "cloud1-allow-http"
  network = "default"

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
  name    = "cloud1-allow-https"
  network = "default"

  # Puerto estándar HTTPS/TLS.
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["cloud1"]
}
