output "cluster_endpoint" {
    description     = "endpoint of cluster"
    value           =   module.eks.cluster_endpoint
}

output "kubeconfig" {
    description     = "config created by eks module"
    value           = module.eks.kubeconfig
}