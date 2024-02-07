module "thanos_fargate_profile" {
  source  = "terraform-aws-modules/eks/aws//modules/fargate-profile"
  version = "~> 19.0"

  name         = "thanos"
  cluster_name = local.name

  subnet_ids = [module.vpc.private_subnets[1]]
  selectors = [
    {
      namespace = "thanos"
    }
  ]
}

module "thanos_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  bucket_prefix            = "monitoring-metrics-${var.environment}"
  acl                      = "private"
  control_object_ownership = true
  object_ownership         = "ObjectWriter"
  force_destroy            = true
}

resource "kubernetes_namespace" "thanos" {
  metadata {
    name = "thanos"
  }
}

resource "kubernetes_secret" "thanos_s3_bucket" {
  metadata {
    name      = "thanos-s3-bucket"
    namespace = "thanos"
  }

  type = "Opaque"

  data = {
    thanos_s3_bucket = yamlencode({
      "thanos-s3-bucket.yaml" : {
        "type" : "s3",
        "config" : {
          "bucket" : module.thanos_s3_bucket.s3_bucket_id,
          "endpoint" : "s3.us-east-1.amazonaws.com",
          "encryptsse" : "true"
        }
      }
    })
  }

  depends_on = [kubernetes_namespace.thanos]
}
