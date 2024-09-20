resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b1aa9b42d"] # Can use Amazon's default OIDC thumbprint
  url = data.terraform_remote_state.eks.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_role" "alb_controller_role" {
  name = "eks-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc_provider.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "alb_controller_policy" {
  name = "ALBControllerPolicy"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:GetCertificate",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "iam:PassRole",
          "iam:ListRoles",
          "iam:GetRole"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller_policy_attach" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

# resource "aws_iam_policy" "alb_controller_policy" {
#   name        = "alb-ingress-controller"
#   description = "IAM policy for ALB Ingress Controller"
#   policy      = data.aws_iam_policy_document.alb_controller_policy.json
# }

# data "aws_iam_policy_document" "alb_controller_policy" {
#   statement {
#     actions   = [
#       "elasticloadbalancing:*",
#       "ec2:Describe*",
#       "acm:ListCertificates",
#       "acm:DescribeCertificate",
#       "iam:ListRoles", 
#       "iam:GetRole"]
#     resources = ["*"]
#   }
# }

resource "aws_iam_role_policy_attachment" "alb_controller_policy_attachment" {
  role       = aws_iam_role.eks_alb_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

resource "aws_iam_role" "eks_alb_role" {
  name = "eks-alb-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "kubernetes_service_account" "aws_load_balancer_controller_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks_alb_role.arn
    }
  }

  depends_on = [ data.terraform_remote_state.eks ]
}
