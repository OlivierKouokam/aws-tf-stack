#!/bin/bash

sudo hostnamectl set-hostname terraform-tf && \
echo "terraform-tf" | sudo tee /etc/hostname && \
sudo sed -i 's/127.0.1.1.*/127.0.1.1 terraform-tf/' /etc/hosts

sudo apt update
sudo apt install git python3 -y

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker ubuntu
sudo systemctl start docker
systemctl enable docker

docker run -d --name eazylabs --privileged -v /var/run/docker.sock:/var/run/docker.sock -p 1993:1993 eazytraining/eazylabs:latest

sudo apt update && sudo apt install -y gnupg software-properties-common
sudo apt install wget tee -y
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install terraform

# ============================
# Installer AWS CLI si nécessaire
# ============================
sudo snap install aws-cli --classic