resource "kubernetes_ingress" "klipbored-ingress" {
  metadata {
    name      = "klipbored-ingress"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class"                        = "alb"
      "alb.ingress.kubernetes.io/scheme"                   = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"              = "ip"
      # "alb.ingress.kubernetes.io/listen-ports"             = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      # "alb.ingress.kubernetes.io/healthcheck-path"         = "/healthz"
      "alb.ingress.kubernetes.io/certificate-arn"          = "arn:aws:acm:eu-west-2:883463338978:certificate/6a98c78c-ffb7-41b0-a091-3df6a69bc476"  # Optional if using HTTPS
    }
  }

  spec {
    rule {
      host = "klipbored.com"

      http {
        path {
          path     = "/"
          path_type = "Prefix"

          backend {
            service_name = "frontend-service"
            service_port = 80
          }
        }
        path {
          path     = "/api/"
          path_type = "Prefix"

          backend {
            service_name = "backend-service"
            service_port = 80
          }
        }
        path {
          path     = "/prometheus"
          path_type = "Prefix"

          backend {
            service_name = "prometheus"
            service_port = 9090
          }
        }
      }
    }
  }
}
