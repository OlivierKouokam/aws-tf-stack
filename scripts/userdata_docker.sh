#!/bin/bash
sudo apt update
sudo apt install git python3 -y

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker ubuntu
sudo systemctl start docker
sudo systemctl enable docker
docker run -d --name eazylabs --privileged -v /var/run/docker.sock:/var/run/docker.sock -p 1993:1993 eazytraining/eazylabs:latest


# echo "MY AWS EC2"

# echo "#!/bin/bash"

# sudo apt update 
# cat <<EOF > docker-compose-vscode.yaml 
# version: '3.7'
# services:
#   nginx-proxy:
#     restart: always
#     image: jwilder/nginx-proxy
#     container_name: nginx-proxy
#     ports:
#     - "80:80"
#     - "443:443"
#     networks:
#       - vsNetwork
#     environment:
#       DHPARAM_GENERATION: "false"
#     volumes:
#       - /var/run/docker.sock:/tmp/docker.sock:ro
#       - ./etc/nginx/certs:/etc/nginx/certs
#       - ./etc/nginx/vhost.d:/etc/nginx/vhost.d
#       - nginx_proxy_html:/usr/share/nginx/html
  
#   nginx-proxy-letsencrypt:
#     restart: always
#     image: jrcs/letsencrypt-nginx-proxy-companion
#     container_name: nginx-proxy-letsencrypt
#     networks:
#     - vsNetwork
#     volumes:
#     - /var/run/docker.sock:/var/run/docker.sock:ro
#     - ./etc/nginx/certs:/etc/nginx/certs
#     - ./etc/nginx/vhost.d:/etc/nginx/vhost.d
#     - nginx_proxy_html:/usr/share/nginx/html
#     environment:
#       DEFAULT_EMAIL: tbagor23@gmail.com
#       NGINX_PROXY_CONTAINER: nginx-proxy
#   vscode:
#     restart: always
#     image: lscr.io/linuxserver/code-server:latest
#     container_name: vscode
#     networks:
#     - vsNetwork
#     environment:
#       PASSWORD: "password"
#       DEFAULT_WORKSPACE: /config/workspace
#       TZ: Etc/UTC
#       VIRTUAL_HOST: vscode.ddns.net
#       LETSENCRYPT_HOST: vscode.ddns.net
# volumes:
#     nginx_proxy_html:
# networks:
#   vsNetwork:
# EOF

# sudo docker compose -f docker-compose-vscode.yaml up -d