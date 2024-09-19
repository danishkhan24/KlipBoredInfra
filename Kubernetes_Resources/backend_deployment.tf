resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "backend-deployment"
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend"
        }
      }

      spec {
        container {
          name  = "backend"
          image = "883463338978.dkr.ecr.eu-west-2.amazonaws.com/klipbored-backend:latest"

          port {
            container_port = 80  # Use the correct port for the backend
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "backend" {
  metadata {
    name      = "backend-service"
    namespace = "default"
  }

  spec {
    selector = {
      app = "backend"
    }

    port {
      protocol    = "TCP"
      port        = 80  # Use the correct port for the backend
      target_port = 5000
    }

    type = "ClusterIP"
  }
}
