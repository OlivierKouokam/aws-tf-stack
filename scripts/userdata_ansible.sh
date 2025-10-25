#!/bin/bash
# Mettre à jour les dépôts et les paquets du système
sudo apt update && sudo apt upgrade -y

# apt-cache policy ansible
# or
# apt list -a ansible

# Ajouter le PPA officiel d'Ansible
sudo apt-add-repository ppa:ansible/ansible

# Mettre à jour les dépôts après avoir ajouté le PPA
sudo apt update

# Installer une version spécifique d'Ansible via apt (par exemple, version 2.9.0)
sudo apt install ansible=2.10.7+merged+base+2.10.8+dfsg-1 -y
sudo apt install git sshpass -y


# #!/bin/bash
# #cloud-config
# # Script de démarrage (User Data) – installation de Ansible version 2.18.x

# # --- Mise à jour des dépôts & paquets du système ---
# echo "Mise à jour du système..."
# apt-get update -y
# apt-get upgrade -y

# # --- Installer les dépendances nécessaires pour ajouter un PPA ---
# echo "Installation de software-properties-common..."
# apt-get install -y software-properties-common

# # --- Ajouter le PPA officiel d’Ansible ---
# echo "Ajout du dépôt Ansible PPA..."
# apt-add-repository --yes --update ppa:ansible/ansible

# # --- Mise à jour des dépôts après ajout du PPA ---
# echo "Mise à jour des dépôts après ajout du PPA..."
# apt-get update -y

# # --- Installer Ansible version 2.18.x (verrouillage explicite) ---
# # Remarque : le paquet exact dépendra de ce que le PPA fournit pour Ubuntu.
# # Exemple : si le paquet est “ansible=2.18.10+…” ou similaire.
# ANSIBLE_VERSION="2.18.10+dfsg-1"  # adapter selon ce que le dépôt affiche
# echo "Installation de Ansible version ${ANSIBLE_VERSION}..."
# apt-get install -y ansible=${ANSIBLE_VERSION}

# # --- Installer Git et sshpass ---
# echo "Installation de git et sshpass..."
# apt-get install -y git sshpass

# # --- Vérifier la version installée d’Ansible ---
# echo "Vérification de la version d’Ansible installée..."
# ansible --version

# echo "Script d’installation terminé."
