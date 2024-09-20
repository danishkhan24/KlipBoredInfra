resource "kubernetes_ingress_v1" "klipbored_ingress" {
  metadata {
    name      = "klipbored-ingress"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class"                        = "alb"
      "alb.ingress.kubernetes.io/scheme"                   = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"              = "ip"
      "alb.ingress.kubernetes.io/certificate-arn"          = "arn:aws:acm:eu-west-2:883463338978:certificate/6a98c78c-ffb7-41b0-a091-3df6a69bc476"
    }
  }

  spec {
    default_backend {
      service {
        name = "frontend-service"
        port {
          number = 80
        }
      }
    }

    rule {
      host = "klipbored.com"

      http {
        path {
          path     = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "frontend-service"
              port {
                number = 80
              }
            }
          }
        }

        path {
          path     = "/api/"
          path_type = "Prefix"

          backend {
            service {
              name = "backend-service"
              port {
                number = 80
              }
            }
          }
        }

        path {
          path     = "/prometheus"
          path_type = "Prefix"

          backend {
            service {
              name = "prometheus"
              port {
                number = 9090
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service_account.aws_load_balancer_controller_sa]
}
