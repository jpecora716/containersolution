data "aws_caller_identity" "current" {}

# Create a Load Balancer Policy for the AWS ALB as per:
resource "aws_iam_policy" "ekslb" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "AWS LoadBalancer Controller IAM Policy"

  policy = file("iam-policy.json")
  
}

# Attach the Load Balancer Policy after the Role is created
resource "aws_iam_role_policy_attachment" "eks_lbcontroller" {
  depends_on = [
    aws_iam_role.eks_alb
  ]
  policy_arn = aws_iam_policy.ekslb.arn
  role               = "AmazonEKSLoadBalancerControllerRole"
}

data "tls_certificate" "eks" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# Creates an Identity Provider required by the ALB
resource "aws_iam_openid_connect_provider" "eks_alb" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# Policy for the OIDC required by the ALB
data "aws_iam_policy_document" "oidc" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_alb.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_alb.arn]
      type        = "Federated"
    }
  }
}
# Attached OIDC policy to the Role AmazonEKSLoadBalancerControllerRole
resource "aws_iam_role" "eks_alb" {
  assume_role_policy = data.aws_iam_policy_document.oidc.json
  name               = "AmazonEKSLoadBalancerControllerRole"
}

# Creates k8s Service Account with permissions to create the ALB used by the Ingress
resource "kubernetes_service_account" "eks_alb" {
  metadata {
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name" = "aws-load-balancer-controller"
    }
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.eks_alb.name}"
      }
  }
}

# Creates k8s CRD's required by for the ALB
data "kubectl_path_documents" "manifests" {
    pattern = "crds.yaml"
}

resource "kubectl_manifest" "eks_alb" {
  depends_on = [
    data.aws_eks_cluster.cluster 
  ]
    count     = length(data.kubectl_path_documents.manifests.documents)
    yaml_body = element(data.kubectl_path_documents.manifests.documents, count.index)
}

# Applies ALB helm chart
resource "helm_release" "eks_alb" {
  depends_on = [
    data.aws_eks_cluster.cluster 
  ]
  name       = "eks"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "clusterName"
    value = local.cluster_name
  }
}

# Creates policy for worker nodes required by ELB as per: https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/1171
resource "aws_iam_role_policy" "worker_policy" {
  name   = "worker_policy"
  role   = module.eks.worker_iam_role_name
  policy = file("worker-iam-policy.json")
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "example" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.example.private_key_pem
  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "cert" {
  private_key      = tls_private_key.example.private_key_pem
  certificate_body = tls_self_signed_cert.example.cert_pem
  provisioner "local-exec" {
    command = "sed s@REPLACE_ACM_ARN@${self.arn}@ pan.yaml.tpl > pan.yaml"
  }
}

