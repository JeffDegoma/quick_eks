#/bin/bash
#install dependencies and terraform INSIDE an awscli docker container and
#spin up a dev EKS infrastructure without the need to install terraform or python on local machine


#Tools
yum install -y jq gzip nano tar git unzip wget

#Terraform
curl -o /tmp/terraform.zip -LO https://releases.hashicorp.com/terraform/0.13.1/terraform_0.13.1_linux_amd64.zip
cd /tmp
unzip -o /tmp/terraform.zip
chmod +x terraform && mv terraform /usr/local/bin/