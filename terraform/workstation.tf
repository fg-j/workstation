provider "google" {
  project     = var.project
  region      = "us-central1"
  credentials = var.service_account_key

  version = "~> 2.5"
}

variable "project" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "service_account_key" {
  type = string
}

resource "google_compute_disk" "default" {
  name  = "${var.vm_name}-disk"
  type  = "pd-ssd"
  zone  = "us-central1-a"
  image = "ubuntu-os-cloud/ubuntu-1804-lts"
  size = 1000
  physical_block_size_bytes = 4096
}

resource "google_compute_attached_disk" "default" {
  disk     = google_compute_disk.default.id
  instance = google_compute_instance.default.id
  zone    = "us-central1-a"
}

resource "google_compute_instance" "default" {
  name         = var.vm_name
  machine_type = "n1-standard-8"
  zone         = "us-central1-a"
  tags = [var.vm_name]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.ip_address.address
    }
  }

  metadata = {
    ssh-keys = "${format("ubuntu:%s", tls_private_key.my-key.public_key_openssh)}"
  }
}

resource "google_compute_address" "ip_address" {
  name = "${var.vm_name}-address"
}

resource "tls_private_key" "my-key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "google_compute_firewall" "external" {
  name        = "${var.vm_name}-external"
  network     = "default"
  target_tags = [var.vm_name]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

output "ssh_private_key" {
  sensitive = true
  value     = tls_private_key.my-key.private_key_pem
}

output "vm_ip" {
  value = google_compute_address.ip_address.address
}

