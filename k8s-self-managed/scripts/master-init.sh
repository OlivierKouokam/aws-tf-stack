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
sudo sysctl --system
sudo kubeadm init --pod-network-cidr="10.244.0.0/16" --ignore-preflight-errors=all > /tmp/restult.out
cat /tmp/restult.out
tail -2 /tmp/restult.out > /tmp/join_command.sh;

token=$(sudo awk '/kubeadm join/{flag=1} flag{printf "%s ", $0} END{print ""}' /tmp/restult.out)


sudo snap install aws-cli --classic

# ------------------------
# Sauvegarder le token K3s dans SSM
# ------------------------
aws ssm put-parameter --name "/k8s/token" --type "SecureString" \
--value "$token" --overwrite --region "us-east-1"

#User configuration
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config

# attendre que l'API server soit prêt
until kubectl get nodes &>/dev/null; do
  echo "Waiting for Kubernetes API..."
  sleep 5
done


#install flannel plugin
kubectl apply --validate=false -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
