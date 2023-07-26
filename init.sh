#/bin/bash
#install dependencies, terraform and kubectl INSIDE an awscli docker container

#Tools
yum install -y jq gzip nano tar git unzip wget yum-utils shadow-utils

#Terraform
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum -y install terraform
# curl -o /tmp/terraform.zip -LO https://releases.hashicorp.com/terraform/1.3.5/terraform_1.3.5_linux_amd64.zip
# cd /tmp
# unzip  -o /tmp/terraform.zip

# chmod +x terraform && mv terraform /usr/local/bin/

#kubectl
# curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.23.6/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

echo "Terraform running"

tail -f /dev/null #keeps container running