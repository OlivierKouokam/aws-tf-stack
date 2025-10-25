#!/bin/bash
apt update
apt install git python3 -y

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu
systemctl start docker
systemctl enable docker

# git clone https://github.com/diranetafen/cursus-devops.git
git clone https://github.com/OlivierKouokam/cursus-devops-stack.git

cd cursus-devops-stack/jenkins
# cd ../jenkins
docker compose up -d
docker compose -f docker-compose-official.yml up -d

sleep 180
JENKINS_CONTAINER=$(docker ps -a --filter "ancestor=jenkins/jenkins" --format "{{.ID}}")
docker exec $JENKINS_CONTAINER cat /var/jenkins_home/secrets/initialAdminPassword > /tmp/initialAdminPassword.txt

if [[ -n "$ENABLE_ZSH" && $ENABLE_ZSH == "true" ]]
then
    echo "We are going to install zsh"
     yum -y install zsh git
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
echo
echo "Follow these steps to add an external agent:"
echo

echo "# Comment ajouter un agent dans le dashboard Jenkins ?"
echo
echo "# Voici la démarche classique pour ajouter un agent Jenkins (appelé aussi node ou esclave) :"
echo

echo "# Étapes pour ajouter un agent dans Jenkins :"
echo
echo "1. Connecte-toi à Jenkins Master (via le navigateur sur le port 8080)."
echo "2. Va dans Manage Jenkins > Manage Nodes and Clouds (ou juste Manage Nodes selon ta version)."
echo "3. Clique sur New Node (ou New Agent)."
echo "4. Donne un nom à ton agent (par ex. staging-agent), choisis Permanent Agent et clique sur OK."
echo "5. Configure le noeud :"
echo "   - Nombre d’exécuteurs (combien de builds parallèles)."
echo "   - Répertoire de travail (ex: /home/jenkins/agent)."
echo "   - Labels (optionnel, pour cibler cet agent dans les pipelines)."
echo "   - Mode : \"Usage réservé\" ou \"n'importe quel travail\"."
echo "6. Dans la section Launch method (méthode de lancement) :"
echo "   - Choisis Launch agent by connecting it to the controller (via JNLP)."
echo "7. Enregistre."
echo "8. Jenkins va te fournir une commande JNLP et un secret/token que tu dois utiliser sur la machine agent pour lancer le processus agent."
echo

echo "8.a- Sur la machine agent :"
echo "   - Installe Java (openjdk-11 par exemple)."
echo "   - Télécharge le client remoting.jar (la version donnée par Jenkins)."
echo "   - Lance la commande JNLP fournie (ou adapte ton userdata pour la lancer automatiquement)."
echo "   - Exemple de commande fournie par Jenkins :"
echo "     java -jar agent.jar -jnlpUrl http://<JENKINS_MASTER_IP>:8080/computer/staging-agent/jenkins-agent.jnlp"
echo

echo "8.b- Dans un conteneur docker :"
echo "docker run -d --name jenkins-agent --restart unless-stopped --network <JENKINS-NETWORK> -v /var/run/docker.sock:/var/run/docker.sock -v jenkins-agent-data:/home/jenkins jenkins/inbound-agent:latest -url http://jenkins:8080 -secret <AGENT-SECRET> -name <AGENT-NAME> -workDir \"/home/jenkins\""
echo

# docker run -d \
#   --name jenkins-agent \
#   --restart unless-stopped \
#   --network <JENKINS-NETWORK> \
#   -v /var/run/docker.sock:/var/run/docker.sock \
#   -v jenkins-agent-data:/home/jenkins \
#   jenkins/inbound-agent:latest \
#   -url http://jenkins:8080 \
#   -secret <AGENT-SECRET> \
#   -name <AGENT-NAME> \
#   -workDir "/home/jenkins"
