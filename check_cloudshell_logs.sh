#!/bin/bash
# Script to check CloudShell VM serial console logs for kubeconfig authentication
# This verifies that issue #348 solution is working properly

set -e

echo "🔍 Checking CloudShell VM Serial Console Logs"
echo "=============================================="

# Check if Azure CLI is available
if ! command -v az >/dev/null 2>&1; then
    echo "❌ Azure CLI not found. Please install Azure CLI first:"
    echo "   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    exit 1
fi

# Check authentication
echo "🔐 Verifying Azure authentication..."
if ! az account show >/dev/null 2>&1; then
    echo "❌ Not authenticated to Azure. Please run:"
    echo "   az login"
    exit 1
fi

# Get resource group and VM info
RESOURCE_GROUP=$(az group list --query "[?contains(name, 'rg')].name" -o tsv | head -1)
if [ -z "$RESOURCE_GROUP" ]; then
    echo "❌ Could not find resource group"
    exit 1
fi

echo "📍 Using Resource Group: $RESOURCE_GROUP"

# Check if CloudShell VM exists
VM_NAME="cloudshell_vm"
if ! az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" >/dev/null 2>&1; then
    echo "❌ CloudShell VM not found in resource group $RESOURCE_GROUP"
    exit 1
fi

echo "🖥️  CloudShell VM found: $VM_NAME"

# Get VM status
VM_STATUS=$(az vm get-instance-view --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "instanceView.statuses[?code=='PowerState/running'].displayStatus" -o tsv)
if [ "$VM_STATUS" = "VM running" ]; then
    echo "✅ VM Status: Running"
else
    echo "⚠️  VM Status: $VM_STATUS (may still be starting up)"
fi

# Get VM creation time
CREATED_TIME=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "timeCreated" -o tsv)
echo "⏰ VM Created: $CREATED_TIME"

# Get serial console logs
echo ""
echo "📋 Retrieving Serial Console Logs..."
echo "===================================="

# Note: Serial console logs may take a few minutes to appear after VM creation
az vm boot-diagnostics get-boot-log --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --output table 2>/dev/null || {
    echo "⚠️  Boot diagnostics may not be available yet. VM might still be initializing."
    echo "    Try again in a few minutes."
}

# Check cloud-init logs specifically
echo ""
echo "🔍 Checking for kubeconfig authentication in logs..."
echo "=================================================="

# Look for our specific kubeconfig authentication section
BOOT_LOG=$(az vm boot-diagnostics get-boot-log --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" 2>/dev/null || echo "")

if echo "$BOOT_LOG" | grep -q "AZURE_AUTH.*Authenticating with Azure"; then
    echo "✅ Found Azure authentication section in logs"
elif echo "$BOOT_LOG" | grep -q "az login.*service-principal"; then
    echo "✅ Found Azure service principal login in logs"
else
    echo "⚠️  Azure authentication section not yet visible in logs"
    echo "    VM may still be running cloud-init. Check again in a few minutes."
fi

if echo "$BOOT_LOG" | grep -q "az aks get-credentials"; then
    echo "✅ Found AKS credentials retrieval in logs"
else
    echo "⚠️  AKS credentials retrieval not yet visible in logs"
fi

if echo "$BOOT_LOG" | grep -q "/root/.kube/config.*created"; then
    echo "✅ Kubeconfig file creation confirmed"
else
    echo "⚠️  Kubeconfig file creation not yet confirmed in logs"
fi

# Check if we can get VM IP for direct testing
VM_IP=$(az vm list-ip-addresses --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv 2>/dev/null)
if [ -n "$VM_IP" ] && [ "$VM_IP" != "null" ]; then
    echo ""
    echo "🌐 VM Public IP: $VM_IP"
    echo "   You can SSH to test kubectl access once cloud-init completes:"
    echo "   ssh azureuser@$VM_IP"
    echo "   kubectl cluster-info"
fi

echo ""
echo "💡 Tips for troubleshooting:"
echo "   - Cloud-init can take 5-10 minutes to complete"
echo "   - Check /var/log/cloud-init-output.log on the VM for detailed logs"
echo "   - Look for 'AZURE_AUTH' and 'AKS_CREDS' markers in the logs"
echo "   - Verify kubectl works: kubectl get nodes"

echo ""
echo "✅ Script completed. Re-run in a few minutes if authentication not yet visible."
