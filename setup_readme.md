# Windows installation
- install wsl
- install ubuntu
- update ubuntu
sudo apt install -y git curl unzip

Install Terraform 

sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" sudo apt-get update && sudo apt-get install terraform

Install AWS CLI curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" unzip awscliv2.zip sudo ./aws/install

# Once inside WSL/Linux



