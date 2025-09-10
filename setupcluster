#!/usr/bin/env bash
set -euo pipefail

# ---------- USER VARIABLES: edit these to match your current config ----------
SUBSCRIPTION_ID="<your-subscription-id>"
RESOURCE_GROUP="<your-rg>"                 # e.g. my-aks-rg
NEW_CLUSTER_NAME="<new-aks-cluster>"      # name for the new AKS cluster
LOCATION="eastus"                          # example; use your current region
K8S_VERSION="<k8s-version>"                # e.g. 1.27.6  (use same version as old cluster if desired)
NODEPOOL_NAME="nodepool0"
NODE_VM_SIZE="Standard_DS2_v2"
NODE_COUNT=3
VNET_SUBNET_ID="/subscriptions/xxx/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"  # <-- your existing subnet id to reuse
SERVICE_PRINCIPAL_CLIENT_ID=""             # optional - leave empty to use managed identity
SERVICE_PRINCIPAL_SECRET=""
ENABLE_AAD="false"                         # set to true if your template used AAD integration
NETWORK_PLUGIN="azure"                     # or "kubenet" if you used that earlier
NETWORK_POLICY=""                          # e.g. "calico" or empty

# optional autoscaler settings
ENABLE_AUTOSCALER="false"
MIN_COUNT=1
MAX_COUNT=5

# ---------- end user variables ----------

az account set --subscription "$SUBSCRIPTION_ID"

# Create resource group if doesn't exist (comment out if already present)
az group create -n "$RESOURCE_GROUP" -l "$LOCATION"

# Build az aks create base command
AZ_AKS_CREATE_CMD=(az aks create
  --resource-group "$RESOURCE_GROUP"
  --name "$NEW_CLUSTER_NAME"
  --location "$LOCATION"
  --kubernetes-version "$K8S_VERSION"
  --nodepool-name "$NODEPOOL_NAME"
  --node-count "$NODE_COUNT"
  --node-vm-size "$NODE_VM_SIZE"
  --network-plugin "$NETWORK_PLUGIN"
  --vnet-subnet-id "$VNET_SUBNET_ID"
  --enable-managed-identity
  --node-osdisk-size 128
  --generate-ssh-keys
  --yes
)

# Add network policy if set
if [ -n "$NETWORK_POLICY" ]; then
  AZ_AKS_CREATE_CMD+=(--network-policy "$NETWORK_POLICY")
fi

# Add AAD (if required)
if [ "$ENABLE_AAD" = "true" ]; then
  AZ_AKS_CREATE_CMD+=(--enable-aad)
fi

# Add SP if you want service principal instead of managed identity
if [ -n "$SERVICE_PRINCIPAL_CLIENT_ID" ]; then
  AZ_AKS_CREATE_CMD+=(--service-principal "$SERVICE_PRINCIPAL_CLIENT_ID" --client-secret "$SERVICE_PRINCIPAL_SECRET")
fi

# If you want autoscaler
if [ "$ENABLE_AUTOSCALER" = "true" ]; then
  AZ_AKS_CREATE_CMD+=(--enable-cluster-autoscaler --min-count "$MIN_COUNT" --max-count "$MAX_COUNT")
fi

# Force VMSS (az aks uses VMSS by default now, but ensure nodepool type is VMSS)
# Create the cluster
echo "Creating AKS cluster: $NEW_CLUSTER_NAME in $RESOURCE_GROUP..."
"${AZ_AKS_CREATE_CMD[@]}"

echo "AKS cluster created. Getting credentials..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$NEW_CLUSTER_NAME" --overwrite-existing

echo "Done. You are now configured to use the new cluster's kubeconfig."
