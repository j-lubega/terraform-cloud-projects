provider "google" {
  project = "uplifted-air-485115-i5"
  region  = "us-east1"
  zone    = "us-east1-b"
}

# 1. Firewall Rule to allow HTTP traffic (Port 80)
resource "google_compute_firewall" "web_access" {
  name    = "allow-http-web"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"] 
  target_tags   = ["web-server"]
}

# 2. Free Tier VM with an Automatic Startup Script
resource "google_compute_instance" "web_app" {
  name         = "free-web-app"
  machine_type = "e2-micro" # Always Free
  zone         = "us-east1-b"
  tags         = ["web-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11" # Lightweight for free tier
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
      # This gives the VM a Public IP so you can visit it in a browser
    }
  }

  # Startup script: Installs Nginx and creates a simple HTML page
  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "<h1>Hello from GCP Free Tier!</h1><p>Provisioned via Terraform.</p>" > /var/www/html/index.html
    systemctl start nginx
  EOT
}

# 3. Output the Public IP address
output "web_app_url" {
  value = "http://${google_compute_instance.web_app.network_interface.0.access_config.0.nat_ip}"
}
