$mainSubscription = '065b0ab4-5905-4ce8-bada-275c71fe7696'
$resourceGroup = 'MySolrGroup'
$clusterName = 'MySolrCluster'

# Login to Azure
az login
az account set --subscription $mainSubscription

# Create resource group
az group create --name $resourceGroup --location westus

# Create cluster
az aks create --resource-group $resourceGroup --name $clusterName --node-vm-size Standard_B2ms --generate-ssh-keys --node-count 2 --enable-managed-identity

# $agentPoolProfiles = az aks show --resource-group $resourceGroup --name $clusterName --query agentPoolProfiles | ConvertFrom-Json
# $nodepoolName = $agentPoolProfiles.name
# az aks scale --resource-group $resourceGroup --name $clusterName --node-count 3 --nodepool-name $nodepoolName

# Install Kubernetes CLI (kubectl)
# az aks install-cli

# Create local configuration file to talk to the AKS Cluster
az aks get-credentials --resource-group $resourceGroup --name $clusterName

# Create file share
$storageAccountName = 'hwsolrstorage1'
$fileShareName = 'solrstorage'
az storage account create -n $storageAccountName -g $resourceGroup -l westus --sku Standard_LRS
$storageAccountConnectionString = az storage account show-connection-string -n $storageAccountName -g $resourceGroup -o tsv
az storage share create -n $fileShareName --connection-string $storageAccountConnectionString
$storageAccountSecretKey = az storage account keys list --resource-group $resourceGroup --account-name $storageAccountName --query "[0].value" -o tsv

kubectl create secret generic solr-storage-volume-key --from-literal=azurestorageaccountname=$storageAccountName --from-literal=azurestorageaccountkey=$storageAccountSecretKey

# Install Istio
istioctl install

# Configure Istio sidecar injector
kubectl label namespace default istio-injection=enabled

# Apply the predefined Ingress controller rule to the cluster
kubectl apply -f .\zookeeper.yaml
kubectl apply -f .\solr.yaml

# $solrPod = kubectl get pod -l app=solr -o jsonpath='{.items[0].metadata.name}'
# kubectl exec -i -t $solrPod -- /bin/bash

# Figure out the public IP of the Solr Ingress controller and launch it in a browser
$publicIp = kubectl get service --output=json -o jsonpath='{.items[*].status.loadBalancer.ingress[*].ip}'
$solrAddress = 'http://' + $publicIp + '/solr/#/~cloud'
start $solrAddress

# Restart pods in a deployment 
kubectl rollout restart StatefulSet solr

# From any solr node
./server/scripts/cloud-scripts/zkcli.sh -zkhost solr-zookeeper-0.solr-zookeeper-headless.default.svc.cluster.local:2181 -cmd clusterprop -name legacyCloud -val true