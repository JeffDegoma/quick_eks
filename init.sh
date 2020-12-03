#/bin/bash
#install dependencies, terraform and kubectl INSIDE an awscli docker container

#Tools
yum install -y jq gzip nano tar git unzip wget

#Terraform
curl -o /tmp/terraform.zip -LO https://releases.hashicorp.com/terraform/0.13.1/terraform_0.13.1_linux_amd64.zip
cd /tmp
unzip  -o /tmp/terraform.zip

chmod +x terraform && mv terraform /usr/local/bin/

#kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

tail -f /dev/null #keeps container running