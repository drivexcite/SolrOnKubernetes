# Login to Azure
az login

# Create the resource group for the cluster
az group create --name ClusterResourceGroup --location westus

# Create a managed Kubernetes Cluster in AKS with 8 Standard DS1 VMs.
az aks create --resource-group ClusterResourceGroup --name KubeCluster --node-count 8 --node-vm-size Standard_DS1_v2 -- enable-addons monitoring --generate-ssh-keys

# Install Kubernetes CLI (kubectl)
az aks install-cli

# Create local configuration file to talk to the AKS Cluster
az aks get-credentials --resource-group ClusterResourceGroup --name KubeCluster

# Create a Kubernetes Service account with cluster admin privileges (aparently, not recommended for production)
# kubectl create serviceaccount --namespace kube-system tiller
# kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

# To install helm using Chocolatey
# choco install kubernetes-helm 

# Add the incubator repository to Helm sources.
# helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/

# Initialize Helm with the service account and install Tiller in the AKS Cluster
# helm init --service-account tiller

# Fetch the Solr charts
helm fetch incubator/solr

# Unzip-Tgz.ps1 & ExpandTar.ps1 must be in the path
.\Unzip-Tgz.ps1 .\solr-1.2.0.tgz

# Actually decompress Helm Solr chart
.\Expand-Tar.ps1 .\solr-1.2.0.tar

# Create a Solr YAML file using the Helm template
helm template .\solr-1.2.0\solr\ --set image.tag=8.2.0 --set replicaCount=6 --set volumeClaimTemplates.storageClassName=managed-premium  --name solr > ./solr.yaml

# Apply the Helm generated template to the Cluster using kubectl
# This will install by default a 3-node Solr Cluster and a 3-node Zookeper coordinator.
kubectl apply -f .\solr.yaml

# Fetch the nginx ingress chart and decompress.
helm fetch stable/nginx-ingress
.\Unzip-Tgz.ps1 .\nginx-ingress-1.19.0.tgz
.\Expand-Tar.ps1 .\nginx-ingress-1.19.0.tar

# Create the YAML for the nginx-ingress artifacts
helm template .\nginx-ingress-1.19.0\nginx-ingress --name nginx-ingress --set controller.replicaCount=2 --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux > nginx-ingress.yaml
kubectl apply -f .\nginx-ingress.yaml

# Apply the predefined Ingress controller rule to the cluster
kubectl apply -f .\solr-ingress.yaml

# Figure out the public IP of the Solr Ingress controller and launch it in a browser
$publicIp = kubectl get service --output=json -o jsonpath='{.items[*].status.loadBalancer.ingress[*].ip}'
$solrAddress = 'http://' + $publicIp + '/solr/#/~cloud'
start $solrAddress