#!/bin/bash
set -xe
#Kubernetes script 
sudo apt update && sudo apt upgrade -y
sudo apt install apt-transport-https curl -y

#install containerd
sudo apt install containerd -y
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

#kubernetes components
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

#network configuration
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# ============================
# Installer AWS CLI si nécessaire
# ============================
sudo snap install aws-cli --classic
# ============================
# Récupérer la commande join depuis SSM
# ============================
token=$(aws ssm get-parameter --name "/k8s/token"  \
    --with-decryption --region "us-east-1" \
    --query 'Parameter.Value' --output text)
token=$(echo "$token" | tr -d '\\\n')
if [[ -z "$token" ]]; then
    echo "Erreur : impossible de récupérer la commande join depuis SSM" >&2
    exit 1
fi
token="$token --ignore-preflight-errors=all"
echo "Commande join récupérée depuis SSM : $token"

# ============================
# Rejoindre le cluster Kubernetes
# ============================
sudo bash -c "$token"

echo "=== Worker node ajouté avec succès au cluster Kubernetes ==="
