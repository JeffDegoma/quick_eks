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
    subnets         = module.vpc.public_subnets
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

    azs             = ["us-east-1a", "us-east-1b"] //more azs
    public_subnets  = ["10.0.101.0/24", "10.0.5.0/24"] //more public subnets

    enable_nat_gateway = false
    enable_vpn_gateway = false
    enable_dns_hostnames = true

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
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
    load_config_file       = false
    version                = "~> 1.11"
}



resource "kubernetes_service" "node-service" {
  metadata {
    name = "server"
    labels = {
      "test" = "server"
    }
  }
  spec {
    selector = {
        test = "node-pod" //bound to all pods labeled "node-pod"
    }
    port {
      port =  3000
      protocol = "TCP"
    }

  }
}


resource "kubernetes_deployment" "backend" {
      metadata {
        name = "node-deployment"
        labels = {
            test = "node-deployment"
        }
    }

    spec {
        replicas = 1 //increase to scale

        selector {
            match_labels = {
                test = "node-pod"
            }
        }

        template { //template(required)
            metadata { //metadata(required)
                labels = {
                    test  = "node-pod"
                }
            }

            spec { //spec(required)
                container {
                    image = "180430814937.dkr.ecr.us-east-1.amazonaws.com/docker_images:stellar_server"
                    name = "stellar-server"
                    port {
                      container_port = 3000
                    }

                    resources {
                        limits {
                            cpu = "750m"
                            memory = "512Mi"
                        }
                        requests {
                            cpu = "300m"
                            memory = "50Mi"
                        }
                    }
                }
            }
        }
    }
}

//front-end service
resource "kubernetes_service" "nginx-service" {
  metadata {
    name = "frontend-service"
  }
  spec {
    selector = {
      test = "frontend-pod" //bound to all pods "frontend-pod"
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

//front-end deployment
resource "kubernetes_deployment" "front-end" {
    //metadata
    //spec
    metadata {
        name = "frontend-deployment"
        labels = {
            test = "frontend-deployment"
        }
    }

    spec {
        replicas = 1 //increase to scale up

        selector {
            match_labels = {
                test = "frontend-pod"
            }
        }


        template { //template(required)
            metadata { //metadata(required)
                labels = {
                    test  = "frontend-pod"
                }
            }

            spec { //spec(required)
                container {
                    image = "180430814937.dkr.ecr.us-east-1.amazonaws.com/docker_images:stellar_client"
                    name = "stellar-client"

                    resources {
                        limits {
                            cpu = "750m"
                            memory = "512Mi"
                        }
                        requests {
                            cpu = "300m"
                            memory = "50Mi"
                        }
                    }
                }
            }
        }
    }

}