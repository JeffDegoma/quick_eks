terraform {
    required_version = ">= 1.2.0"
}


locals {
    name   = "drone-k8s"
}


provider "aws" {
    version =  ">= 4.55"
    region  = var.region
}

module "eks" {
    source          = "terraform-aws-modules/eks/aws"
    cluster_name    =  var.cluster_name
    version         = "19.13.1"
    
    vpc_id          = module.vpc.vpc_id 
    subnet_ids               = module.vpc.private_subnets
    cluster_endpoint_public_access = true
    # cluster_endpoint_private_access = true 

    node_security_group_tags = {
        "kubernetes.io/cluster/${var.cluster_name}" = null
    }
    eks_managed_node_group_defaults = {
        instance_types = ["t3.medium"]
        attach_cluster_primary_security_group = true
        vpc_security_group_ids                = [aws_security_group.worker_groups_management.id]
        iam_role_additional_policies = {
            additional = aws_iam_policy.additional.arn
        }
    }
    eks_managed_node_groups = {
            default_node_group = {
                use_custom_launch_template = false
            }
    blue = {}
    green = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
      labels = {
        Environment = "test"
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }

      taints = {
        dedicated = {
          key    = "dedicated"
          value  = "gpuGroup"
          effect = "NO_SCHEDULE"
        }
      }

      update_config = {
        max_unavailable_percentage = 33 # or set `max_unavailable`
      }

      tags = {
        ExtraTag = "example"
      }
    }
  }
}


resource "aws_iam_policy" "additional" {
  name = "${local.name}-additional"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

module "vpc" {
    source          = "terraform-aws-modules/vpc/aws"
    name            =  "april2023_vpc"
    cidr            = "10.0.0.0/16"

    azs             = ["us-east-1a", "us-east-1b"] 
    public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"] 
    private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

    enable_nat_gateway = true
    enable_dns_hostnames = true
    single_nat_gateway = true

    public_subnet_tags = {
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        "kubernetes.io/role/elb"                      = "1"
    }
    
}

resource "aws_security_group" "worker_groups_management" {
    
    name_prefix     = "worker_group_management"
    vpc_id          =  module.vpc.vpc_id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks     =   ["10.0.0.0/8"]
    }

}

provider "kubernetes" {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        # This requires the awscli to be installed locally where Terraform is executed
        args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
}




# resource "kubernetes_service" "node-service" {
#   metadata {
#     name = "server"
#     labels = {
#       "test" = "server"
#     }
#   }
#   spec {
#     selector = {
#         test = "node-pod" //bound to all pods labeled "node-pod"
#     }
#     port {
#       port =  3000
#       protocol = "TCP"
#     }

#   }
# }


# resource "kubernetes_deployment" "backend" {
#       metadata {
#         name = "node-deployment"
#         labels = {
#             test = "node-deployment"
#         }
#     }

#     spec {
#         replicas = 1 //increase to scale

#         selector {
#             match_labels = {
#                 test = "node-pod"
#             }
#         }

#         template { //template(required)
#             metadata { //metadata(required)
#                 labels = {
#                     test  = "node-pod"
#                 }
#             }

#             spec { //spec(required)
#                 container {
#                     image = "180430814937.dkr.ecr.us-east-1.amazonaws.com/docker_images:project_server"
#                     name = "stellar-server"
#                     port {
#                       container_port = 3000
#                     }

#                     resources {
#                         limits = {
#                             cpu = "750m"
#                             memory = "512Mi"
#                         }
#                         requests = {
#                             cpu = "300m"
#                             memory = "50Mi"
#                         }
#                     }
#                 }
#             }
#         }
#     }
# }

# //front-end service
# resource "kubernetes_service" "nginx-service" {
#   metadata {
#     name = "frontend-service"
#   }
#   spec {
#     selector = {
#       test = "frontend-pod" //bound to all pods "frontend-pod"
#     }
#     port {
#       port        = 80
#       target_port = 80
#     }

#     type = "LoadBalancer"
#   }
# }

# //front-end deployment
# resource "kubernetes_deployment" "front-end" {
#     //metadata
#     //spec
#     metadata {
#         name = "frontend-deployment"
#         labels = {
#             test = "frontend-deployment"
#         }
#     }

#     spec {
#         replicas = 1 //increase to scale up

#         selector {
#             match_labels = {
#                 test = "frontend-pod"
#             }
#         }


#         template { //template(required)
#             metadata { //metadata(required)
#                 labels = {
#                     test  = "frontend-pod"
#                 }
#             }

#             spec { //spec(required)
#                 container {
#                     image = "180430814937.dkr.ecr.us-east-1.amazonaws.com/docker_images:project_client"
#                     name = "project-client"

#                     resources {
#                         limits = {
#                             cpu = "750m"
#                             memory = "512Mi"
#                         }
#                         requests = {
#                             cpu = "300m"
#                             memory = "50Mi"
#                         }
#                     }
#                 }
#             }
#         }
#     }

# }