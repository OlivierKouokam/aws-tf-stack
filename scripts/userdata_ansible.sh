#!/bin/bash
# Mettre à jour les dépôts et les paquets du système
sudo apt update && sudo apt upgrade -y

# Ajouter le PPA officiel d'Ansible
sudo apt-add-repository ppa:ansible/ansible

# Mettre à jour les dépôts après avoir ajouté le PPA
sudo apt update

# Installer une version spécifique d'Ansible via apt (par exemple, version 2.9.0)
sudo apt install ansible=2.10.7+merged+base+2.10.8+dfsg-1 -y
sudo apt install git sshpass -y

