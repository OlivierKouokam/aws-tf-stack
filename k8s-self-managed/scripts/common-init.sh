#!/bin/bash
set -xe

# ============================
# Variables passées depuis Terraform
# ============================
k8s_version="${k8s_version:-v1.30.0}"
cluster_cidr="${cluster_cidr:-10.244.0.0/16}"
ssm_param_name="${ssm_param_name:-/k8s/token}"
region="${region:-us-east-1}"

echo "=== Starting Kubernetes installation ==="
echo "Version: $k8s_version"
echo "CIDR: $cluster_cidr"

# ============================
# Mise à jour du système
# ============================
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https curl gpg

# ============================
# Installation de containerd
# ============================
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# ============================
# Désactivation du swap
# ============================
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab

# ============================
# Modules kernel & sysctl
# ============================
sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# ============================
# Dépôt Kubernetes
# ============================
k8s_major_version=$(echo "$k8s_version" | cut -d'.' -f1-2)
curl -fsSL https://pkgs.k8s.io/core:/stable:/$k8s_major_version/deb/Release.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$k8s_major_version/deb/ /" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list

# ============================
# Installation kubeadm, kubelet, kubectl
# ============================
sudo apt update
sudo apt install -y kubeadm kubelet kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable kubelet

echo "=== Kubernetes binaries installed ==="
kubeadm version --short
kubelet --version
kubectl version --client --short

# ============================
# Initialisation du cluster
# ============================
sudo kubeadm init --pod-network-cidr="${cluster_cidr}" | tee /tmp/result.out

# Extraire la commande join
tail -n 2 /tmp/result.out > /tmp/join_command.sh
token=$(cat /tmp/join_command.sh)

# ============================
# Installer AWS CLI si manquant
# ============================
if ! command -v aws &>/dev/null; then
    if command -v yum &>/dev/null; then
        sudo yum install -y awscli
    else
        sudo snap install aws-cli --classic
    fi
fi

# Sauvegarder le token dans SSM
aws ssm put-parameter --name "${ssm_param_name}" --type "SecureString" \
    --value "${token}" --overwrite --region "${region}"

# ============================
# Configuration kubectl
# ============================
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# ============================
# Installer Flannel (CNI)
# ============================
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo "=== Kubernetes installation and cluster init completed successfully! ==="
