#!/bin/bash

# ============================
# Configuration du hostname
# ============================
sudo hostnamectl set-hostname terraform-tf && \
echo "terraform-tf" | sudo tee /etc/hostname && \
sudo sed -i 's/127.0.1.1.*/127.0.1.1 terraform-tf/' /etc/hosts

# ============================
# Mise à jour système et installation de base
# ============================
sudo apt update
sudo apt install -y git python3 curl wget unzip

# ============================
# Installation de Docker
# ============================
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker ubuntu
sudo systemctl enable --now docker

# ============================
# Lancement du conteneur Eazylabs
# ============================
docker run -d --name eazylabs --privileged \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -p 1993:1993 eazytraining/eazylabs:latest

# ============================
# Installation d'une version FIXE de Terraform
# ============================

TERRAFORM_VERSION="1.13.4"
cd /tmp

# Télécharger le binaire officiel
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Extraire et déplacer dans /usr/local/bin
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/
sudo chmod +x /usr/local/bin/terraform

# Vérification
terraform -version

# ============================
# Installation AWS CLI
# ============================
echo
echo "Installation de aws-cli"
echo
sudo snap install aws-cli --classic

echo "✅ Installation terminée : Terraform $(terraform -version | head -n 1) installé."