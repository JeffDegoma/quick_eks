terraform {
    required_version = ">= 0.12.0"
}

data "aws_eks_cluster" "cluster" {
    name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
    name = module.eks.cluster_id
}


provider "aws" {
    version = ">= 2.28.1"
    region  = var.region
}

module "eks" {
    source          = "terraform-aws-modules/eks/aws"
    cluster_name    =  var.cluster_name
    cluster_version = "1.17"
    
    vpc_id          = module.vpc.vpc_id 
    subnets         = module.vpc.private_subnets
    version         = "12.2.0"
    cluster_create_timeout = "1h"
    cluster_endpoint_private_access = true 


  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.small"
      additional_userdata           = "echo foo bar"
      asg_desired_capacity          = 1
      additional_security_group_ids = [aws_security_group.worker_groups_management.id]
    },
  ]
}

module "vpc" {
    source          = "terraform-aws-modules/vpc/aws"
    name            =  "stellar_vpc"
    cidr            = "10.0.0.0/16"

    azs             = ["ap-southeast-1a"] //more azs
    private_subnets = ["10.0.1.0/24" ] //more private subnets
    public_subnets  = ["10.0.101.0/24"] //more public subnets

    enable_nat_gateway = false
    enable_vpn_gateway = false
    enable_dns_hostnames = true
    
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
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
    load_config_file       = false
    version                = "~> 1.11"
}

resource "kubernetes_deployment" "stellar" {
    //metadata
    //spec
    metadata {
        name = "stellar-demo"
        labels = {
            test = "stellar-login"
        }
    }

    spec {
        replicas = 2

        template { //template(required)
            
            metadata { //metadata(required)
                labels = {
                    test  = "stellar-demo"
                }
            }

            spec { //spec(required)
                container {
                    image = "image"
                    name = "image name declaration"

                    resources {
                        limits {
                            cpu = "0.5"
                            memory = "512Mi"
                        }
                        requests {
                            cpu = "250m"
                            memory = "50Mi"
                        }
                    }
                }
            }
        }
    }


}

