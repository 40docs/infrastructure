# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the **infrastructure** repository within the 40docs platform - a Terraform-based Infrastructure as Code (IaC) solution that deploys Azure resources including hub-spoke network topology with FortiWeb NVA and Azure Kubernetes Service (AKS) cluster with GitOps capabilities.

## Azure CLI Integration Requirements

### Authentication Verification
**MANDATORY**: Before performing any Azure operations, Claude must:

1. **Verify Azure Authentication**:
   ```bash
   # Check current authentication status
   az account show
   ```

2. **Authentication Validation**:
   - If not authenticated, guide user to authenticate:
     ```bash
     az login --use-device-code
     # Or for service principals:
     az login --service-principal -u <app-id> -p <password-or-cert> --tenant <tenant-id>
     ```

3. **Subscription Management**:
   - Verify active subscription is correct:
     ```bash
     az account list --output table
     ```
   - If multiple subscriptions available, guide user to select appropriate one:
     ```bash
     az account set --subscription "<subscription-id-or-name>"
     ```

4. **Permission Validation**:
   - Verify subscription has necessary permissions for infrastructure operations
   - Check resource provider registrations:
     ```bash
     az provider list --query "[?namespace=='Microsoft.ContainerService'].{Namespace:namespace, State:registrationState}" -o table
     az provider list --query "[?namespace=='Microsoft.Network'].{Namespace:namespace, State:registrationState}" -o table
     az provider list --query "[?namespace=='Microsoft.Compute'].{Namespace:namespace, State:registrationState}" -o table
     ```

### Azure CLI Best Practices
Claude must actively use `az` commands for:

1. **Resource Verification and Cross-Checking**:
   ```bash
   # Verify resource group exists
   az group show --name "<resource-group-name>"

   # List all resources in resource group
   az resource list --resource-group "<resource-group-name>" --output table

   # Check specific resource status
   az aks show --resource-group "<rg-name>" --name "<cluster-name>"
   az network vnet show --resource-group "<rg-name>" --name "<vnet-name>"
   ```

2. **Deployment Status Validation**:
   ```bash
   # Check deployment history
   az deployment group list --resource-group "<resource-group-name>" --output table

   # Get specific deployment details
   az deployment group show --resource-group "<rg-name>" --name "<deployment-name>"

   # Monitor ongoing deployments
   az deployment group list --resource-group "<rg-name>" --query "[?properties.provisioningState=='Running']"
   ```

3. **Network Configuration Analysis**:
   ```bash
   # Analyze network topology
   az network vnet list --resource-group "<rg-name>" --output table
   az network vnet subnet list --resource-group "<rg-name>" --vnet-name "<vnet-name>" --output table

   # Check network security groups
   az network nsg list --resource-group "<rg-name>" --output table
   az network nsg rule list --resource-group "<rg-name>" --nsg-name "<nsg-name>" --output table

   # Verify public IPs and DNS
   az network public-ip list --resource-group "<rg-name>" --output table
   az network dns zone list --resource-group "<rg-name>" --output table
   ```

4. **Security Assessment**:
   ```bash
   # Check VM security status
   az vm list --resource-group "<rg-name>" --show-details --output table

   # Validate NVA status (FortiWeb)
   az vm get-instance-view --resource-group "<rg-name>" --name "<fortiweb-vm-name>"

   # Check AKS security configuration
   az aks show --resource-group "<rg-name>" --name "<cluster-name>" --query "aadProfile"
   az aks show --resource-group "<rg-name>" --name "<cluster-name>" --query "networkProfile"
   ```

5. **Monitoring and Logging Review**:
   ```bash
   # Check diagnostic settings
   az monitor diagnostic-settings list --resource "<resource-id>"

   # Review activity logs
   az monitor activity-log list --resource-group "<rg-name>" --start-time "<start-time>"

   # Check metrics availability
   az monitor metrics list-definitions --resource "<resource-id>"
   ```

### FortiWeb NVA Specific Commands
```bash
# Check FortiWeb VM status and configuration
az vm show --resource-group "<rg-name>" --name "<fortiweb-vm-name>" --show-details

# Verify FortiWeb network interfaces
az vm nic list --vm-name "<fortiweb-vm-name>" --resource-group "<rg-name>"

# Check FortiWeb public IP assignments
az network public-ip list --resource-group "<rg-name>" --query "[?contains(name,'fortiweb') || contains(name,'nva')]"

# Validate FortiWeb load balancer configuration (if HA setup)
az network lb list --resource-group "<rg-name>" --output table
az network lb probe list --resource-group "<rg-name>" --lb-name "<lb-name>"
```

### AKS Integration Commands
```bash
# Get AKS credentials for kubectl access
az aks get-credentials --resource-group "<rg-name>" --name "<cluster-name>" --overwrite-existing

# Check AKS cluster health
az aks show --resource-group "<rg-name>" --name "<cluster-name>" --query "powerState"

# Validate node pool status
az aks nodepool list --resource-group "<rg-name>" --cluster-name "<cluster-name>" --output table

# Check AKS addon status (monitoring, policy, etc.)
az aks addon list --resource-group "<rg-name>" --name "<cluster-name>"
```

### CLOUDSHELL VM Detection and Diagnostics
**MANDATORY**: Claude must detect if running on the infrastructure's CLOUDSHELL VM by checking hostname:

1. **Hostname Detection**:
   ```bash
   # Check if running on CLOUDSHELL VM
   hostname
   ```
   - If hostname returns `CLOUDSHELL`, then Claude is running on the cloudshell_vm deployed by cloudshell.tf
   - This VM has computer_name configured as "CLOUDSHELL" (cloudshell.tf:255)

2. **Cloud-init Log Access** (Only when hostname is CLOUDSHELL):
   ```bash
   # View complete cloud-init execution logs
   cat /var/log/cloud-init-output.log

   # Monitor cloud-init logs in real-time
   tail -f /var/log/cloud-init-output.log

   # Check cloud-init status and completion
   cloud-init status

   # View cloud-init configuration that was applied
   cat /var/log/cloud-init.log
   ```

3. **CLOUDSHELL VM Diagnostics**:
   ```bash
   # Check VM metadata and configuration
   sudo dmidecode -s system-product-name
   curl -H "Metadata:true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq

   # Verify attached data disks (home, docker, ollama)
   lsblk
   df -h

   # Check GPU status (VM has NVIDIA V100 GPUs)
   nvidia-smi

   # Verify Kubernetes credentials are available
   kubectl cluster-info

   # Check Docker status and containers
   docker ps
   docker images
   ```

4. **Infrastructure Context** (When running on CLOUDSHELL):
   - VM is deployed with Standard_NC12s_v3 size (12 vCPU, 224 GB RAM, 2x V100 GPUs)
   - Has direct access to AKS cluster with kubectl configured
   - Contains SSH keys, API keys, and infrastructure secrets via cloud-init
   - Connected to cloudshell_network (10.0.1.0/24) separate from hub-spoke topology
   - Has internet access via public IP with DNS record (cloudshell.domain.com)

**Usage Guidelines**:
- When hostname is CLOUDSHELL, Claude has privileged access to infrastructure logs and diagnostics
- Can troubleshoot deployment issues using cloud-init logs
- Has full kubectl access to AKS cluster for application debugging
- Can use Azure CLI with pre-configured credentials for resource management

## Common Development Commands

### Terraform Validation and Formatting
```bash
# Format Terraform files (always run before committing)
terraform fmt

# Validate syntax (use init with -backend=false for local testing)
terraform validate

# Initialize without backend for local validation only
terraform init -backend=false

# Note: Do NOT run terraform plan/apply locally
# These commands require GitHub secrets and Azure state backend
```

### Security and Quality Checks
```bash
# Security scanning (if lacework CLI available)
lacework iac scan

# Additional security tools (if available)
tfsec .
trivy config .
checkov -d .
```

### GitHub Actions Workflow Commands
```bash
# Trigger infrastructure deployment workflow
gh workflow run infrastructure.yml

# Check workflow status
gh run list -w infrastructure.yml

# View workflow logs
gh run view --log
```

## Architecture Overview

### Hub-Spoke Network Topology
- **Hub Network**: Contains FortiWeb NVA (Network Virtual Appliance) for centralized security
  - External subnet: Management and public access
  - Internal subnet: NVA backend connectivity
  - Multiple VIPs for different applications
- **Spoke Network**: Houses AKS cluster and application workloads
  - AKS subnet: Kubernetes nodes
  - Pod CIDR: Container networking (10.244.0.0/16)

### Key Infrastructure Components
- **FortiWeb NVA**: Web Application Firewall and traffic inspection
- **AKS Cluster**: Kubernetes cluster with system, CPU, and optional GPU node pools
- **Container Registry**: Private Azure Container Registry for images
- **GitOps**: Flux v2 for automated application deployment
- **Security**: Lacework agent for runtime protection
- **Certificate Management**: cert-manager with Let's Encrypt integration
- **DNS**: Azure DNS with automatic CNAME record management

### Resource Organization
```
├── Core Infrastructure
│   ├── resource-group.tf          # Resource group and base config
│   ├── hub-network.tf            # Hub network with FortiWeb
│   ├── hub-nva.tf               # FortiWeb NVA configuration
│   └── spoke-network.tf         # Spoke network with AKS
├── Kubernetes Platform
│   ├── spoke-k8s_cluster.tf                    # AKS cluster
│   ├── spoke-k8s_infrastructure.tf             # Core K8s services
│   ├── spoke-k8s_infrastructure-cert-manager.tf # Certificate management
│   ├── spoke-k8s_infrastructure-laceworks.tf    # Security monitoring
│   └── spoke-k8s_infrastructure-*.tf           # Additional services
├── Applications
│   ├── spoke-k8s_application-docs.tf           # Documentation
│   ├── spoke-k8s_application-dvwa.tf           # Security testing
│   ├── spoke-k8s_application-extractor.tf      # Data processing
│   └── spoke-k8s_application-*.tf              # Other applications
└── Configuration
    ├── variables.tf              # Input variables with validation
    ├── outputs.tf               # Output values
    ├── locals.tf                # Local values and VM images
    ├── terraform.tf             # Provider requirements
    └── cloud-init/              # VM initialization scripts
```

## Development Guidelines

### Git Workflow Standards (MANDATORY)

**CRITICAL**: This repository has protected main branch requiring pull requests. ALL code changes MUST follow this workflow:

#### Branch Protection Policy
- **NEVER push directly to main branch** - It is protected and will reject direct pushes
- **ALWAYS use feature branches** for any changes or commits
- **ALWAYS create pull requests** for merging to main
- **NO exceptions** - Even documentation changes require PR workflow

#### Mandatory Git Workflow Steps

1. **Create Feature Branch**: Before making any changes
   ```bash
   # Check current branch (should be main and clean)
   git status
   git pull origin main

   # Create descriptive feature branch using naming conventions
   git checkout -b feature/description-of-changes
   # OR git checkout -b fix/issue-description
   # OR git checkout -b docs/documentation-update
   # OR git checkout -b refactor/code-improvement
   # OR git checkout -b chore/maintenance-task
   ```

2. **Make and Commit Changes**: Work in feature branch
   ```bash
   # Make your changes, then stage and commit
   git add .
   git commit -m "descriptive commit message following conventional commits"
   ```

3. **Push Feature Branch**: Push to remote with upstream tracking
   ```bash
   # Push feature branch to origin
   git push -u origin feature/description-of-changes
   ```

4. **Create Pull Request**: Use GitHub CLI for consistent PR creation
   ```bash
   # Create pull request with descriptive title and body
   gh pr create --title "Brief description of changes" --body "Detailed explanation of what changed and why"

   # Example with full details:
   gh pr create \
     --title "Add new terraform validation rules" \
     --body "## Summary
   - Added variable validation for IP addresses
   - Updated terraform formatting rules
   - Improved error handling

   ## Testing
   - [x] terraform fmt passes
   - [x] terraform validate passes
   - [x] All security scans pass"
   ```

5. **Branch Naming Conventions**: Use consistent prefixes
   - `feature/` - New features or enhancements
   - `fix/` - Bug fixes and corrections
   - `docs/` - Documentation updates
   - `refactor/` - Code restructuring without functionality changes
   - `chore/` - Maintenance, tooling, or administrative tasks

#### Error Recovery Procedures

**If you're on main branch with uncommitted changes**:
```bash
# Create feature branch immediately
git stash
git checkout -b fix/emergency-branch-creation
git stash pop
git add .
git commit -m "Emergency commit to feature branch"
git push -u origin fix/emergency-branch-creation
gh pr create --title "Emergency fix" --body "Moved changes from main to feature branch"
```

**If you accidentally committed to main branch**:
```bash
# Create feature branch from current main
git checkout -b fix/moved-from-main
git push -u origin fix/moved-from-main

# Reset main to origin
git checkout main
git reset --hard origin/main

# Create PR from feature branch
gh pr create --title "Moved accidental main commits" --body "These commits were accidentally made on main"
```

#### Pre-commit Checklist
Before creating any pull request, ensure:
- [ ] Feature branch created and checked out
- [ ] `terraform fmt` executed and files formatted
- [ ] `terraform init -backend=false && terraform validate` passes
- [ ] All changes staged and committed with descriptive messages
- [ ] Feature branch pushed to origin with upstream tracking
- [ ] Pull request created with descriptive title and body
- [ ] PR URL reported for review and merge

#### Git Workflow Automation Rules

**For Claude Code AI Assistant**:
1. **Always check current branch** before any git operations
2. **Never attempt to push to main** - Error immediately if detected
3. **Auto-create feature branches** when changes are needed
4. **Always use descriptive branch names** based on the type of work
5. **Always create PR after pushing** feature branch
6. **Report PR URL** to user after successful creation
7. **Implement retry logic** for network failures during git operations

### Terraform Standards
- **Variable Naming**: Always use `snake_case` (underscores), never `kebab-case` (hyphens)
- **Resource Naming**: Consistent underscore naming following HashiCorp conventions
- **Template Variables**: All cloud-init template variables use lowercase `snake_case`
- **Provider Versions**: Specific version constraints defined in terraform.tf (lines 14-63)
- **Variable Validation**: Extensive input validation with regex patterns for IPs, subnets, domains
- **Tags**: Consistent tagging using local.standard_tags for all resources

### File Organization Principles
- **Separation of Concerns**: Network, compute, and applications in separate files
- **Resource Grouping**: Related resources grouped by function (hub-*, spoke-*, k8s_*)
- **Application Pattern**: Each application follows standardized template in separate file
- **Infrastructure Services**: Core K8s services prefixed with `infrastructure-`

### Variable Configuration
Key variable patterns from variables.tf:
- **Application Toggles**: `application_*` boolean variables to enable/disable apps
- **Network Configuration**: IP ranges with CIDR validation
- **Environment Sizing**: `production_environment` affects VM sizes and scaling
- **Security Variables**: Sensitive values properly marked and validated

## CI/CD Pipeline Architecture

### GitHub Actions Workflow (.github/workflows/infrastructure.yml)
1. **Trigger Conditions**:
   - Push to main branch
   - Changes to `*.tf` or `cloud-init/*` files
   - Manual workflow dispatch

2. **Deployment Logic**:
   - Controlled by `vars.DEPLOYED` repository variable
   - `DEPLOYED=true`: Runs plan/apply workflow
   - `DEPLOYED=false`: Runs destroy workflow
   - No variable: Skips deployment

3. **Workflow Jobs**:
   - **plan**: Terraform planning with detailed output
   - **apply**: Automated deployment with state management
   - **destroy**: Infrastructure teardown when needed

4. **Environment Variables**:
   - 30+ secret and variable mappings for complete configuration
   - Azure authentication via service principal
   - Terraform state stored in Azure Storage Account

### State Management
- **Backend**: Azure Storage Account with remote state locking
- **Key Strategy**: Branch name as state key for multi-environment support
- **Security**: Backend config provided via GitHub secrets during CI/CD

## Application Deployment Patterns

### Standard Application Structure
Each application file follows this pattern:
1. **Public IP**: Dedicated Azure public IP for FortiWeb VIP
2. **DNS Record**: CNAME pointing to FortiWeb FQDN
3. **Flux Configuration**: GitOps kustomization for app deployment
4. **GitHub Integration**: Repository secrets for CI/CD access

### Application Variables
```hcl
# Toggle applications on/off
variable "application_docs" {
  type        = bool
  description = "Deploy Docs application"
  default     = true
}
```

### FortiWeb VIP Configuration
Each app gets dedicated VIP addresses:
- `hub_nva_vip_docs` = "10.0.0.5"
- `hub_nva_vip_dvwa` = "10.0.0.6"
- `hub_nva_vip_ollama` = "10.0.0.7"
- etc.

## Testing and Validation

### Local Development Workflow
1. **Format**: Run `terraform fmt` before any commit
2. **Initialize**: Use `terraform init -backend=false` for syntax checking
3. **Validate**: Run `terraform validate` to check configuration
4. **Security**: Scan with available security tools
5. **Commit**: Follow conventional commit messages

### Pre-deployment Checklist
- [ ] All Terraform files formatted (`terraform fmt`)
- [ ] Configuration validates successfully (`terraform validate`)
- [ ] No security issues identified
- [ ] Variable descriptions and validation rules updated
- [ ] Cloud-init templates use consistent variable naming

### Production Deployment Requirements
- **Never run locally**: `terraform plan/apply` require GitHub secrets
- **State Backend**: Requires Azure Storage Account access
- **Service Principal**: Azure authentication via GitHub secrets
- **Approval Gates**: Manual approval required for production changes

## Security Considerations

### Network Security
- All traffic flows through FortiWeb NVA for inspection
- Network Security Groups with granular controls
- Private endpoints for Azure services where applicable
- Hub-spoke topology provides network segmentation

### Application Security
- Lacework agent deployed for runtime protection
- RBAC enabled on AKS cluster with Azure AD integration
- Certificate management via cert-manager and Let's Encrypt
- Secrets managed through Kubernetes secrets and Azure Key Vault

### Infrastructure Security
- Terraform state encrypted in Azure Storage
- Service principal with minimal required permissions
- Security scanning integrated in CI/CD pipeline
- Resource tagging for governance and cost management

## Critical Issues and Recommendations

### ⚠️ High Availability Concern
**Current Issue**: FortiWeb NVA is deployed as single instance, creating availability risk.

**Recommendations**:
1. Deploy multiple NVA instances across availability zones
2. Implement Azure Standard Load Balancer for traffic distribution
3. Migrate from availability sets to availability zones
4. Add automated failover mechanisms

### Improvement Opportunities
- **Terraform Modules**: Refactor monolithic structure into reusable modules
- **Automated Testing**: Implement Terratest for infrastructure validation
- **Enhanced Monitoring**: Add comprehensive observability for NVA health
- **Documentation**: Expand runbooks and operational procedures

## Troubleshooting Common Issues

### Azure Authentication and Permissions
```bash
# 1. Verify current authentication status
az account show --query "{subscriptionId:id, tenantId:tenantId, user:user.name}" --output table

# 2. Check if authenticated user has required roles
az role assignment list --assignee $(az account show --query user.name --output tsv) --scope "/subscriptions/$(az account show --query id --output tsv)" --output table

# 3. Validate resource provider registrations
az provider list --query "[?registrationState!='Registered'].{Namespace:namespace, State:registrationState}" --output table

# 4. Re-register required providers if needed
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Compute
```

### FortiWeb Marketplace and Licensing Issues
```bash
# Accept FortiWeb marketplace terms (required before deployment)
az vm image terms accept --urn "fortinet:fortinet_fortiweb-vm_v5:fortinet_fw-vm:latest"

# Verify marketplace terms are accepted
az vm image terms show --urn "fortinet:fortinet_fortiweb-vm_v5:fortinet_fw-vm:latest"

# List available FortiWeb SKUs and versions
az vm image list --offer fortinet_fortiweb-vm_v5 --publisher fortinet --all --output table
```

### Network Connectivity and Routing Issues
```bash
# 1. Check VNet peering status
az network vnet peering list --resource-group "<rg-name>" --vnet-name "<hub-vnet-name>" --output table

# 2. Validate route tables
az network route-table list --resource-group "<rg-name>" --output table
az network route-table route list --resource-group "<rg-name>" --route-table-name "<route-table-name>"

# 3. Check NSG rules blocking traffic
az network nsg rule list --resource-group "<rg-name>" --nsg-name "<nsg-name>" --query "[?access=='Deny']" --output table

# 4. Test network connectivity to FortiWeb
az network watcher test-connectivity --source-resource "<vm-resource-id>" --dest-address "<fortiweb-ip>" --dest-port 443
```

### AKS Cluster Issues
```bash
# 1. Check AKS cluster provisioning state
az aks show --resource-group "<rg-name>" --name "<cluster-name>" --query "provisioningState" --output tsv

# 2. Validate node pool health
az aks nodepool show --resource-group "<rg-name>" --cluster-name "<cluster-name>" --name "<nodepool-name>" --query "provisioningState"

# 3. Check AKS system pods status (requires kubectl access)
az aks get-credentials --resource-group "<rg-name>" --name "<cluster-name>" --overwrite-existing
kubectl get pods -n kube-system

# 4. Review AKS activity logs for errors
az monitor activity-log list --resource-group "<rg-name>" --start-time $(date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%SZ') --query "[?contains(resourceId,'aks')]"
```

### Resource Deployment Failures
```bash
# 1. Check recent deployment failures
az deployment group list --resource-group "<rg-name>" --query "[?properties.provisioningState=='Failed']" --output table

# 2. Get detailed error information for failed deployment
az deployment group show --resource-group "<rg-name>" --name "<deployment-name>" --query "properties.error"

# 3. Check resource quotas and limits
az vm list-usage --location "<location>" --query "[?currentValue>=limit].{Name:localName, Current:currentValue, Limit:limit}" --output table

# 4. Validate subscription limits
az network list-usages --location "<location>" --query "[?currentValue>=limit]" --output table
```

### DNS and Certificate Issues
```bash
# 1. Check DNS zone and records
az network dns zone show --resource-group "<rg-name>" --name "<dns-zone>"
az network dns record-set list --resource-group "<rg-name>" --zone-name "<dns-zone>" --output table

# 2. Validate public IP DNS settings
az network public-ip list --resource-group "<rg-name>" --query "[].{Name:name, FQDN:dnsSettings.fqdn, IP:ipAddress}" --output table

# 3. Test DNS resolution
nslookup <application-fqdn>
dig <application-fqdn>

# 4. Check certificate status (if using cert-manager)
kubectl get certificates -A
kubectl describe certificate <cert-name> -n <namespace>
```

### Storage and State Backend Issues
```bash
# 1. Verify Terraform state storage account access
az storage account show --resource-group "<backend-rg>" --name "<storage-account-name>"

# 2. Check storage account permissions
az storage account keys list --resource-group "<backend-rg>" --account-name "<storage-account-name>"

# 3. Validate storage container exists
az storage container show --account-name "<storage-account>" --name "<container-name>"

# 4. List state files in container
az storage blob list --account-name "<storage-account>" --container-name "<container>" --output table
```

### Terraform Validation Errors
```bash
# Check for resource reference errors
terraform validate

# Common issue: Variable naming inconsistencies
# Solution: Ensure all variables use snake_case format

# Check for circular dependencies
terraform graph | dot -Tpng > terraform-graph.png
```

### GitHub Actions Failures
Common causes and solutions:
1. **Invalid Azure credentials**: Verify `AZURE_CREDENTIALS` secret matches az login output
2. **State file access**: Check Azure Storage Account permissions using `az storage account show`
3. **Variable validation**: Ensure all required variables are set in GitHub repository
4. **Resource quotas**: Verify Azure subscription limits using `az vm list-usage`
5. **Network policies**: Check NSG rules and route tables for connectivity issues

## Key Files for Development

- `variables.tf`: All input variables with validation (520 lines)
- `terraform.tf`: Provider requirements and version constraints
- `locals.tf`: VM image configurations and common values
- `outputs.tf`: Resource outputs for external consumption
- `cloud-init/`: VM initialization templates
- `.github/workflows/infrastructure.yml`: CI/CD pipeline definition

## Adding New Applications

### Step-by-step Process:
1. **Create Application File**: `spoke-k8s_application-<name>.tf`
2. **Add VIP Variable**: New VIP IP address in variables.tf
3. **Follow Pattern**: Copy existing application structure
4. **Update Variables**: Add application toggle variable
5. **Test Locally**: Validate syntax and formatting
6. **Deploy**: Commit to trigger CI/CD pipeline

### Example Application Template:
```hcl
# Public IP for application VIP
resource "azurerm_public_ip" "hub_nva_vip_<app>_public_ip" {
  name                = "hub-nva-vip-<app>-public-ip"
  # ... standard configuration
}

# DNS CNAME record
resource "azurerm_dns_cname_record" "<app>" {
  name   = "<app>"
  record = azurerm_public_ip.hub_nva_vip_<app>_public_ip.fqdn
  # ... standard configuration
}

# Flux GitOps configuration
resource "flux_bootstrap_git" "<app>" {
  # ... GitOps configuration
}
```

This infrastructure provides a robust, scalable platform for the 40docs ecosystem with comprehensive security, monitoring, and automation capabilities.

- sync to github with a PR and then merge the PR
