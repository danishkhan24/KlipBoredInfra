resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name      = "prometheus-config"
    namespace = "monitoring"
  }

  data = {
    "prometheus.yml" = <<EOF
global:
scrape_interval: 5s  # How often to scrape targets
scrape_configs:
- job_name: 'backend'
    static_configs:
    - targets: ['backend.default.svc.cluster.local:5000']

web:
  external_url: https://klipbored.com/prometheus
  route_prefix: /prometheus
EOF
  }
}

resource "kubernetes_deployment" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = "monitoring"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prometheus"
      }
    }

    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }

      spec {
        container {
          name  = "prometheus"
          image = "prom/prometheus:v2.30.3"

          args = [
            "--config.file=/etc/prometheus/prometheus.yml",
            "--web.external-url=https://klipbored.com/prometheus",
            "--web.route-prefix=/prometheus"
          ]

          port {
            container_port = 9090
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/prometheus"
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.prometheus_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = "monitoring"
  }

  spec {
    selector = {
      app = kubernetes_deployment.prometheus.spec[0].template[0].metadata[0].labels.app
    }

    port {
      port        = 9090
      target_port = 9090
    }

    type = "ClusterIP"
  }
}
