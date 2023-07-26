# Quick EKS configured through Terraform

## Getting started
```
git clone https://github.com/JeffDegoma/quick_eks.git && cd "$(basename "$_" .git)"
```

Have aws credentials handy to authenticate with the aws-cli
```
export AWS_ACCESS_KEY_ID=YOUR_AWS-ACCESS-KEY-ID
export AWS_SECRET_ACCESS_KEY=YOUR-SECRET-ACCESS-KEY
export AWS_DEFAULT_REGION=YOUR_REGION
```

## Docker(compose)
```
docker-compose -f docker-compose.yml up
```

## What gets built
An aws-cli docker image. Terraform is preinstalled with a basic EKS cluster configuration


## In a new terminal window, start a bash shell inside newly created container
```
docker exec -it eks_terraform_container /bin/bash
```
## Authenticate with the aws-cli
```
aws configure

AWS Access Key ID [None]:
AWS Secret Access Key [None]:
Default region name [None]:
Default output format [None]:
```
##  Deploy EKS cluster through Terraform
```
terraform init

terraform plan
terraform apply
```

## kube config
```
aws eks update-kubeconfig --name {NAME_OF_CLUSTER} --region us-east-1
```

## kubectl
```
kubectl get nodes
kubectl get deploy
kubectl get svc
```
