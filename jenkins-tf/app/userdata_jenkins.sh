#!/bin/bash
sudo apt update
sudo apt install git ansible -y
git clone https://github.com/diranetafen/cursus-devops.git
cd cursus-devops/ansible
ansible-galaxy install -r roles/requirements.yml
ansible-playbook install_docker.yml
sudo usermod -aG docker ubuntu
cd ../jenkins
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
/usr/local/bin/docker-compose up -d

#curl -fsSL https://get.docker.com -o get-docker.sh
#sh get-docker.sh
#sudo usermod -aG docker ubuntu
#sudo systemctl start docker
#systemctl enable docker

#sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#sudo chmod +x /usr/local/bin/docker-compose
#/usr/local/bin/docker-compose -v

#mkdir -p $HOME/jenkins
#cd $HOME/jenkins
#sudo apt install zsh wget -y
#wget https://raw.githubusercontent.com/eazytrainingfr/jenkins-training/master/docker-compose.yml
#/usr/local/bin/docker-compose up -d

sleep 180
sudo docker exec -it jenkins_jenkins_1 cat /var/jenkins_home/secrets/initialAdminPassword > /tmp/initialAdminPassword_sudo.txt
/usr/bin/docker exec -it jenkins_jenkins_1 cat /var/jenkins_home/secrets/initialAdminPassword > /tmp/initialAdminPassword_absolute.txt
/usr/bin/docker exec $(docker ps -a | grep jenkins | awk '{print \$1}') bash -c 'cat /var/jenkins_home/secrets/initialAdminPassword' > /tmp/initialAdminPassword_awk.txt

if [[ !(-z "$ENABLE_ZSH")  &&  ($ENABLE_ZSH == "true") ]]
then
    echo "We are going to install zsh"
    sudo yum -y install zsh git
    echo "ubuntu" | chsh -s /bin/zsh ubuntu
    su - ubuntu  -c  'echo "Y" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
    su - ubuntu  -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    sed -i 's/^plugins=/#&/' /home/ubuntu/.zshrc
    echo "plugins=(git docker docker-compose helm kubectl kubectx minikube colored-man-pages aliases copyfile  copypath dotenv zsh-syntax-highlighting jsontools)" >> /home/ubuntu/.zshrc
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME='agnoster'/g"  /home/ubuntu/.zshrc
else
    echo "The zsh is not installed on this server"
fi
echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
echo -e "to get jenkins password, please use the following command  \n *** docker exec \$(docker ps -a | grep jenkins | awk '{print \$1}') bash -c 'cat /var/jenkins_home/secrets/initialAdminPassword' ***"

#JENKINS_CONTAINER=$(docker ps -a | grep jenkins | awk '{print $1}')
#docker exec -it $JENKINS_CONTAINER /bin/bash -c 'cat /var/jenkins_home/secrets/initialAdminPassword'