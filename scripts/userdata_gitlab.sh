#!/bin/bash
apt update
apt install git python3 -y

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu
systemctl start docker
systemctl enable docker
docker run -d --name eazylabs --privileged -v /var/run/docker.sock:/var/run/docker.sock -p 1993:1993 eazytraining/eazylabs:latest

docker run --name gitlab \
    --privileged -v /srv/gitlab/config:/etc/gitlab \
    -v /srv/gitlab/logs:/var/log/gitlab \
    -v /srv/gitlab/data:/var/opt/gitlab \
    -p 80:80 -d gitlab/gitlab-ce:latest

# docker run --detach \
#   --hostname gitlab.example.com \
#   --publish 443:443 --publish 80:80 --publish 22:22 \
#   --name gitlab \
#   --restart always \
#   --volume gitlab-config:/etc/gitlab \
#   --volume gitlab-logs:/var/log/gitlab \
#   --volume gitlab-data:/var/opt/gitlab \
#   gitlab/gitlab-ce:latest

#sudo mkdir gitlab && cd gitlab
#sudo curl -o docker-compose.yml https://raw.githubusercontent.com/eazytraining/git-training/refs/heads/main/TP-4/docker-compose.yml
#docker compose up -d


# Script de provisionnement pour formater et monter le volume EBS
#   user_data = <<-EOF
#               #!/bin/bash
#               # Formater le volume EBS
#               mkfs.ext4 /dev/sdf

#               # Créer un point de montage
#               mkdir -p /mnt/data

#               # Monter le volume EBS
#               mount /dev/sdf /mnt/data

#               # Ajouter au fstab pour rendre ce montage persistant
#               echo '/dev/sdf /mnt/data ext4 defaults,nofail 0 2' >> /etc/fstab

#               # Optionnel: déplacer l'installation des applications vers /mnt/data
#               # mv /var/www/html /mnt/data/
#               # ln -s /mnt/data/html /var/www/html
#               EOF
