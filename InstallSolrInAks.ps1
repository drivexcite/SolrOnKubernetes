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

# Unzip the tgz file in a solr folder

# Unzip-Tgz.ps1 & ExpandTar.ps1 must be in the path
.\Unzip-Tgz.ps1 .\solr-1.2.0.tgz

# Actually decompress Helm Solr chart
.\Expand-Tar.ps1 .\solr-1.2.0.tar

# Create a Solr YAML file using the Helm template
helm template .\solr-1.2.0\solr\ --set image.tag=8.2.0 --name solr > ./solr.yaml

# Apply the Helm generated template to the Cluster using kubectl
kubectl apply -f .\solr.yaml