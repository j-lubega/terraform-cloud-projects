provider "google" {
  project = "my-gke-projects-485821" # Change this to your GCP Project ID
  region  = "us-central1"
}

# 1. Create the GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "nginx-cluster"
  location = "us-central1-a"

  # We create a small cluster to stay within credits
  initial_node_count = 1

  node_config {
    machine_type = "e2-medium" # Minimum size for GKE
    labels = {
      app = "nginx"
    }
  }

  deletion_protection = false # Allows terraform destroy to work
}

# 2. Kubernetes Provider (Connects Terraform to the new cluster)
provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
}

data "google_client_config" "default" {}

# 3. Create the Nginx Deployment with 3 Replicas
resource "kubernetes_deployment_v1" "nginx" {
  metadata {
    name = "nginx-deployment"
  }

  spec {
    replicas = 3
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      spec {
        container {
          image = "nginx:latest"
          name  = "nginx"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# 4. Create a Load Balancer to access it
resource "kubernetes_service_v1" "nginx_service" {
  metadata {
    name = "nginx-service"
  }
  spec {
    selector = {
      app = "nginx"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

output "load_balancer_ip" {
  value = kubernetes_service_v1.nginx_service.status.0.load_balancer.0.ingress.0.ip
}
