Déploiement
Initialiser Terraform:

bash
terraform init
Vérifier le plan d'exécution:

bash
terraform plan
Appliquer les changements:

bash
terraform apply
Configurer kubectl pour accéder au cluster:

bash
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)
Vérifier la connexion:

bash
kubectl get nodes
Coût estimé
Le coût d'un cluster EKS est composé de:

$0.10 par heure pour le plan de contrôle EKS

Coût des instances EC2 pour les nœuds worker

Coût du stockage EBS si utilisé

Nettoyage
Pour supprimer toutes les ressources:

bash
terraform destroy
Bonnes pratiques supplémentaires
Utiliser des modules Terraform pour réutiliser le code

Implémenter un backend Terraform (comme S3) pour le state

Utiliser des politiques IAM plus restrictives en production

Activer le logging du cluster (cloudwatch)

Configurer des autoscalers (Cluster Autoscaler, Horizontal Pod Autoscaler)

