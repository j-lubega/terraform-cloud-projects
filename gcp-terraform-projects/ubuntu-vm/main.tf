terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = "uplifted-air-485115-i5"
  region  = "us-east1"
  zone    = "us-east1-b"
}

# 1. Create a VPC for your testing environment
resource "google_compute_network" "vpc_network" {
  name                    = "test-network"
  auto_create_subnetworks = true
}

# 2. Firewall Rule for IAP (Required for Console/SSH access)
# This allows Google's IAP range (35.235.240.0/20) to reach your VM on port 22
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-ssh-via-iap"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

# 3. The Free Tier VM Instance
resource "google_compute_instance" "free_vm" {
  name         = "free-ubuntu-vm"
  machine_type = "e2-micro" # Always Free machine type
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30             # Always Free limit
      type  = "pd-standard"  # MUST be pd-standard for Free Tier
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    # Leaving access_config block out ensures NO public IP is assigned
    # Access is handled via IAP in the GCP Console
  }

  # Best Practice: Allow the VM to be stopped for updates
  allow_stopping_for_update = true
}
