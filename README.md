# 40docs Infrastructure

This repository automates the deployment and management of Azure infrastructure and Kubernetes applications using Terraform. It implements a hub-spoke network topology with FortiWeb NVA (Network Virtual Appliance) for security and traffic inspection, along with Azure Kubernetes Service (AKS) for application hosting.

## 🏗️ Architecture Overview

### Network Topology

- **Hub-Spoke Design**: Centralized security and connectivity through FortiWeb NVA
- **Network Segmentation**: Isolated subnets for management, external, and internal traffic
- **Traffic Inspection**: All spoke traffic routed through FortiWeb for security inspection
- **DNS Integration**: Azure DNS zones with CNAME records for application access

### Components

- **Hub Network**: Contains FortiWeb NVA with multiple VIPs for different applications
- **Spoke Network**: Houses AKS cluster with proper subnet delegation
- **Applications**: Containerized apps (docs, dvwa, ollama, extractor, artifacts, video, pretix)
- **Infrastructure Services**: Cert-manager, Flux GitOps, Lacework security monitoring

## 🔄 Recent Updates & Improvements

### ✅ January 2025 - Code Quality & Validation Improvements

**Snake Case Standardization:**
- **Complete Refactoring**: All Terraform variables and resource names now use consistent `snake_case` formatting
- **Variable References Fixed**: 65+ kebab-case variable references converted to snake_case throughout the codebase
- **Resource Naming Updated**: All public IP resources in application files updated for consistency
- **Files Updated**:
  - `hub-nva.tf` (45+ variable references)
  - `spoke-network.tf` (6 variable references)
  - `spoke-k8s_cluster.tf` (1 variable reference)
  - All `spoke-k8s_application-*.tf` files (resource names)

**Terraform Validation Fixes:**
- **Critical Issue Resolved**: Fixed resource reference errors that prevented `terraform validate` from passing
- **Root Cause**: Resource naming inconsistencies between `hub-nva.tf` and application files
- **Solution**: Standardized all public IP resource names across application files
- **Result**: `terraform validate` now returns "Success! The configuration is valid."

**Testing & Documentation Updates:**
- **Instructions Enhanced**: Updated Copilot instructions with proper testing workflow
- **Backend Initialization**: Clarified use of `terraform init -backend=false` for local testing
- **Code Standards**: Added comprehensive Terraform style guide references
- **Validation Workflow**: Documented proper validation and formatting procedures

**Benefits Achieved:**
- ✅ **Zero Validation Errors**: All resource references now resolve correctly
- ✅ **Consistent Naming**: All code follows HashiCorp Terraform best practices
- ✅ **Enhanced Maintainability**: Unified naming convention reduces confusion
- ✅ **Ready for Deployment**: Configuration validated and ready for production use

### ✅ February 2025 - Cloud-Init Template Variable Standardization

**Complete Template Variable Refactoring:**
- **Problem Identified**: Mixed variable naming conventions across cloud-init templates and Terraform files
- **Scope**: CloudShell and FortiWeb NVA template configurations had inconsistent variable patterns
- **Solution Implemented**: Comprehensive refactoring to standardize all template variables to lowercase snake_case

**Changes Made:**

**CloudShell Template Variables:**
- **Before**: Mixed patterns (`VAR_Directory_tenant_ID`, `VAR_KUBECONFIG`, `VAR_Forticnapp_account`)
- **After**: Consistent snake_case (`var_directory_tenant_id`, `var_kubeconfig`, `var_forticnapp_account`)
- **Files Updated**:
  - `cloudshell.tf` - templatefile section (14 variables)
  - `cloud-init/CLOUDSHELL.conf` - variable references (14 locations)

**FortiWeb NVA Template Variables:**
- **Before**: Kebab-case patterns (`VAR-config-system-global-admin-sport`, `VAR-HUB_NVA_USERNAME`)
- **After**: Consistent snake_case (`var_config_system_global_admin_sport`, `var_hub_nva_username`)
- **Files Updated**:
  - `hub-nva.tf` - templatefile section (20 variables)
  - `cloud-init/fortiweb.conf` - variable references (20+ locations)

**Technical Benefits:**
- ✅ **Consistent Naming**: All template variables now follow HashiCorp Terraform best practices
- ✅ **Improved Maintainability**: Unified naming convention reduces developer confusion
- ✅ **Error Prevention**: Consistent patterns prevent template variable mismatches
- ✅ **Code Readability**: Clear, predictable variable naming across all files

**Validation Results:**
- ✅ **Terraform Validate**: All configurations pass validation successfully
- ✅ **No Uppercase Patterns**: Verified zero remaining `VAR_` or `VAR-` uppercase patterns
- ✅ **Template Consistency**: All cloud-init templates use consistent lowercase snake_case variables

## 🚨 Current Status & Critical Issues

### ❌ High Availability Concerns

> **⚠️ CRITICAL**: The current NVA deployment is NOT highly available and represents a single point of failure.

**Issues Identified:**

1. **Single FortiWeb Instance**: Only one NVA deployed, creating availability risk
2. **Availability Sets vs Zones**: Using legacy availability sets instead of availability zones
3. **No Load Balancing**: Missing Azure Load Balancer for traffic distribution
4. **Manual Failover**: No automated failover mechanisms in place

### 🔧 Infrastructure Assessment

**Strengths:**

- ✅ **GitOps Ready**: Flux GitOps implementation for automated deployments
- ✅ **Security Monitoring**: Lacework agent deployed across cluster
- ✅ **Certificate Management**: Automated TLS with cert-manager and Azure DNS
- ✅ **Network Segmentation**: Proper hub-spoke network topology
- ✅ **Application Isolation**: Each app deployed in separate namespaces

**Areas for Improvement:**

- ⚠️ **Resource Limits**: Some applications lack proper resource constraints
- ⚠️ **Security Contexts**: Missing security contexts in some deployments
- ⚠️ **Terraform Structure**: Monolithic structure could benefit from modules

## 🎯 High Availability Recommendations

### Phase 1: Immediate Actions (Critical)

1. **Deploy Multiple NVA Instances**

   ```hcl
   # Recommended: 2+ FortiWeb instances across availability zones
   zones = ["1", "2", "3"]
   vm_count = 2
   ```

2. **Implement Azure Standard Load Balancer**

   ```hcl
   resource "azurerm_lb" "nva_lb" {
     name     = "nva-load-balancer"
     sku      = "Standard"
     # Configure with health probes and backend pools
   }
   ```

3. **Migrate to Availability Zones**

   ```hcl
   # Replace availability_set with:
   availability_zone = var.zone_number
   ```

### Phase 2: Enhanced Resilience

1. **Implement Health Probes**: Configure proper health monitoring for NVA instances
2. **Shared Configuration**: Use Azure Storage Account for NVA configuration synchronization
3. **BGP Routing**: Consider implementing BGP for dynamic route updates
4. **Disaster Recovery**: Multi-region deployment strategy

### Phase 3: Operational Excellence

1. **Infrastructure Modules**: Refactor into reusable Terraform modules
2. **Automated Testing**: Implement infrastructure testing with Terratest
3. **Monitoring & Alerting**: Enhanced observability for NVA health
4. **Documentation**: Comprehensive runbooks and operational procedures

## 🛠️ Developer Workflow

### Local Development & Testing

**Important**: When testing Terraform locally, use `terraform init -backend=false` since provider variables are initialized from GitHub secrets during workflows.

```bash
# Format Terraform files
terraform fmt

# Validate syntax
terraform validate

# Initialize without backend (for local testing)
terraform init -backend=false

# Security scanning (if lacework CLI available)
lacework iac scan

# Note: Do not run terraform plan/apply locally
# These commands require variables from GitHub secrets
```

### Terraform Code Standards

- **Variable Naming**: All variables must use `snake_case` (underscores), never `kebab-case` (hyphens)
- **Resource Naming**: Resource names should use underscores for consistency with Terraform conventions
- **Variable References**: Always use `var.variable_name` format, never `var.variable-name`
- **Code Style**: Follow HashiCorp Terraform style guide and run `terraform fmt` before committing

### CI/CD Pipeline

1. **Trigger**: Changes to `*.tf` or `cloud-init/*` files
2. **Validation**: Format checking, validation, and security scanning
3. **Planning**: Terraform plan with approval gates
4. **Deployment**: Automated apply with state management
5. **Verification**: Post-deployment health checks

## 🤖 Automated Workflows

### Auto-Approval for Documentation PRs

The repository includes an automated workflow that handles documentation-only pull requests:

**Workflow Features:**
- ✅ **Automatic Approval**: PRs containing only documentation changes are auto-approved
- ✅ **Security Restrictions**: Only works for repository owner's PRs
- ✅ **Status Check Integration**: Waits for all required checks to pass
- ✅ **Auto-Merge Ready**: Combines with GitHub's auto-merge feature
- ✅ **Clear Labeling**: Adds "auto-approved" and "documentation" labels

**Workflow Triggers:**
```yaml
# Activates on changes to:
- '**.md'                    # All Markdown files
- 'docs/**'                  # Documentation directory
- '.github/copilot-instructions.md'  # Copilot configuration
```

**Validation Process:**
1. Verifies PR author is repository owner
2. Confirms PR contains only documentation files
3. Waits for all status checks (CodeQL, Lacework) to pass
4. Auto-approves with explanatory message
5. Enables auto-merge functionality

**Testing the Workflow:**
To validate the auto-approval workflow:
1. Create a feature branch with documentation changes
2. Create a pull request to main branch
3. Monitor for automatic approval after status checks pass
4. Verify auto-merge proceeds successfully

## 📁 File Structure

```text
├── hub-nva.tf                           # FortiWeb NVA configuration
├── hub-network.tf                       # Hub network resources
├── spoke-network.tf                     # Spoke network resources
├── spoke-k8s_cluster.tf                 # AKS cluster configuration
├── spoke-k8s_application-*.tf           # Application deployments
├── spoke-k8s_infrastructure-*.tf        # Infrastructure services
├── variables.tf                         # Input variables
├── terraform.tf                         # Provider configuration
├── locals.tf                           # Local values and VM images
├── .github/workflows/
│   ├── infrastructure.yml              # Main CI/CD pipeline
│   └── auto-approve-docs.yml           # Documentation PR auto-approval
└── cloud-init/                         # VM initialization scripts
    ├── fortiweb.conf                   # FortiWeb configuration template
    └── CLOUDSHELL.conf                 # Cloud shell configuration
```

## ⚙️ Configuration

### Key Variables

```hcl
# Environment configuration
production_environment = true          # Production vs development sizing
management_public_ip   = true          # Enable management access

# Application toggles
application_docs       = true          # Deploy documentation app
application_dvwa       = true          # Deploy DVWA security testing
application_ollama     = true          # Deploy AI/ML workloads
```

### Network Configuration

```hcl
# Hub network (contains NVA)
hub-virtual-network_address_prefix = "10.0.0.0/16"
hub-external-subnet_prefix         = "10.0.1.0/24"
hub-internal-subnet_prefix         = "10.0.2.0/24"

# Spoke network (contains AKS)
spoke-virtual-network_address_prefix = "10.1.0.0/16"
spoke-aks-subnet_prefix             = "10.1.1.0/24"
```

## 🔒 Security Features

### Network Security

- **Traffic Inspection**: All traffic flows through FortiWeb NVA
- **Subnet Isolation**: Dedicated subnets for different tiers
- **Network Security Groups**: Granular traffic controls
- **Private Endpoints**: Secure access to Azure services

### Kubernetes Security

- **RBAC**: Role-based access control enabled
- **Network Policies**: Pod-to-pod communication controls
- **Security Monitoring**: Lacework agent for runtime protection
- **Secret Management**: Kubernetes secrets for sensitive data

### Infrastructure Security

- **Managed Identity**: Azure AD integration for service authentication
- **Key Vault Integration**: Secure certificate and secret storage
- **Monitoring**: Comprehensive logging and alerting

## ☸️ Azure Kubernetes Service (AKS) Environment

### Cluster Configuration

The AKS cluster is deployed with enterprise-grade configuration optimized for production workloads:

**Cluster Specifications:**

- **Kubernetes Version**: 1.31.8 (latest stable)
- **SKU Tier**: Standard (production) / Free (development)
- **Network Plugin**: Kubenet with custom pod CIDR
- **Load Balancer**: Azure Standard Load Balancer
- **Container Runtime**: Azure Linux OS with containerd
- **RBAC**: Enabled with Azure AD integration
- **Workload Identity**: Enabled for secure pod-to-Azure service authentication
- **OIDC Issuer**: Enabled for external identity federation

**Node Pool Architecture:**

1. **System Node Pool** (`system`):
   - **Purpose**: Runs critical Kubernetes system components
   - **VM Size**: Production: Standard_D4s_v3 | Dev: Standard_B2s
   - **Auto-scaling**: Production: 3-7 nodes | Dev: 1 node fixed
   - **OS**: Azure Linux with 75 max pods per node
   - **Taints**: Critical addons only in production

2. **CPU Node Pool** (`cpu`):
   - **Purpose**: General-purpose application workloads
   - **VM Size**: Production optimized for CPU-intensive tasks
   - **Auto-scaling**: 3-5 nodes in production
   - **Storage**: Managed disks (256GB) with ultra SSD option
   - **Zones**: Deployed in Availability Zone 1

3. **GPU Node Pool** (`gpu`):
   - **Purpose**: AI/ML workloads requiring GPU acceleration
   - **VM Size**: GPU-enabled instances for CUDA workloads
   - **Node Taints**: `nvidia.com/gpu=true:NoSchedule`
   - **Labels**: `nvidia.com/gpu.present=true`
   - **Conditional**: Deployed only when `gpu_node_pool` variable is enabled

### Container Registry Integration

- **Azure Container Registry**: Integrated for secure image storage
- **Pull Permissions**: AKS cluster has `AcrPull` role assignment
- **Security**: Admin access disabled, anonymous pull disabled
- **SKU**: Standard (production) / Basic (development)

### Monitoring & Observability

- **Azure Monitor**: Integrated with Log Analytics workspace
- **Container Insights**: Real-time monitoring of cluster and workloads
- **Retention**: 30-day log retention policy
- **Streams**: Comprehensive logging including:
  - Container logs (V1 and V2)
  - Kubernetes events and inventory
  - Performance metrics and insights

## 🔄 GitOps Implementation with Flux

### Flux Configuration

The cluster implements a sophisticated GitOps workflow using **Flux v2** for automated application and infrastructure management:

**Flux Extension Configuration:**

```hcl
flux_extension = {
  name              = "flux-extension"
  extension_type    = "microsoft.flux"
  release_namespace = "flux-system"
  features = {
    image-automation-controller = enabled
    image-reflector-controller  = enabled
    helm-controller.detectDrift = enabled
    notification-controller     = enabled
  }
}
```

### Infrastructure Manifests Breakdown

#### 1. Infrastructure Configuration (`infrastructure`)

- **Repository**: `https://github.com/${github_org}/${manifests_infrastructure_repo_name}.git`
- **Sync Interval**: 60 seconds
- **Scope**: Cluster-wide infrastructure components
- **Namespace**: `cluster-config`
- **Components**:
  - Core infrastructure services
  - Base networking and security policies
  - Foundational monitoring and logging

#### 2. Certificate Manager (`cert-manager-clusterissuer`)

- **Purpose**: Automated TLS certificate management
- **Path**: `./cert-manager-clusterissuer`
- **Dependencies**: Infrastructure deployment
- **Features**:
  - **Let's Encrypt Integration**: Automated SSL/TLS certificate provisioning
  - **Azure DNS Integration**: DNS-01 challenge resolution via Azure DNS
  - **Workload Identity**: Secure Azure authentication using federated credentials
  - **ClusterIssuer**: Cluster-wide certificate issuer for all applications

**Certificate Manager Architecture:**

```hcl
cert_manager_identity = {
  name = "cert-manager"
  role = "DNS Zone Contributor"
  federated_credential = "system:serviceaccount:cert-manager:cert-manager"
}
```

#### 3. Application Deployments

Each application follows the GitOps pattern with separate configurations:

**Application Structure:**

```text
├── docs-dependencies/          # Base dependencies (ingress, RBAC)
├── docs/                      # Main application manifests
├── dvwa-dependencies/         # DVWA security testing dependencies
├── dvwa/                      # DVWA application manifests
└── extractor/                 # Data processing application
```

### Infrastructure Components Deep Dive

#### 🛡️ Lacework Security Agent

**Deployment Configuration:**

- **Namespace**: `lacework-agent`
- **Purpose**: Runtime security monitoring and threat detection
- **Integration**: Direct integration with Lacework cloud platform
- **Configuration**:

  ```json
  {
    "tokens": { "AccessToken": "${lw_agent_token}" },
    "serverurl": "https://api.lacework.net",
    "tags": {
      "Env": "k8s",
      "KubernetesCluster": "${cluster_name}"
    }
  }
  ```

**Security Features:**

- **Runtime Protection**: Continuous monitoring of container behavior
- **Vulnerability Assessment**: Image and runtime vulnerability scanning
- **Compliance Monitoring**: CIS benchmarks and compliance checks
- **Threat Detection**: Anomaly detection and security event correlation

#### 🌐 FortiWeb Ingress Integration

**Architecture Overview:**

- **Public IP Assignment**: Each application gets dedicated public IP via FortiWeb VIP
- **DNS Integration**: Automatic CNAME record creation pointing to FortiWeb FQDN
- **Traffic Flow**: Internet → FortiWeb NVA → AKS Services → Pods

**Per-Application Configuration:**

```hcl
fortiweb_integration = {
  public_ip     = "hub-nva-vip_${app}_public_ip"
  dns_record    = "${app}.${dns_zone}"
  vip_config    = "Managed via FortiWeb API"
  ssl_offload   = "Handled by FortiWeb"
}
```

**Security Benefits:**

- **Web Application Firewall**: Layer 7 attack protection
- **SSL/TLS Termination**: Centralized certificate management
- **Traffic Inspection**: Deep packet inspection and content filtering
- **DDoS Protection**: Application-layer DDoS mitigation

#### 🔐 Ingress Helper Services

**Purpose**: Automated FortiWeb configuration management

- **Namespace**: `ingress-helper`
- **Credentials**: Secure storage of FortiWeb admin credentials
- **Automation**: API-driven VIP and policy configuration
- **Integration**: Webhook-based configuration updates

### Application Deployment Patterns

#### GitOps Workflow per Application

1. **Repository Structure**:

   ```text
   manifests-applications/
   ├── branch: docs-version
   ├── branch: dvwa-version
   ├── branch: extractor-version
   └── branch: main (infrastructure)
   ```

2. **Deployment Dependencies**:

   ```mermaid
   graph TD
     A[Infrastructure] --> B[cert-manager-clusterissuer]
     B --> C[Application Dependencies]
     C --> D[Application Deployment]
     D --> E[Post-Deployment Config]
   ```

3. **Flux Kustomizations**:
   - **Dependencies**: Base infrastructure (ingress, RBAC, secrets)
   - **Application**: Main application manifests
   - **Post-Config**: Optional post-deployment configuration

## 🚀 Current Applications

| Application | Purpose | Namespace | Status | GitOps Branch |
|-------------|---------|-----------|--------|---------------|
| **docs** | Documentation hosting | `docs` | ✅ Running | `docs-version` |
| **dvwa** | Security testing | `dvwa` | ✅ Running | `dvwa-version` |
| **extractor** | Data processing | `extractor` | ✅ Running | `extractor-version` |
| **ollama** | AI/ML workloads | Not deployed | ⏸️ Disabled | `ollama-version` |
| **artifacts** | Build artifacts | Not deployed | ⏸️ Disabled | `artifacts-version` |
| **video** | Media streaming | Not deployed | ⏸️ Disabled | `video-version` |
| **pretix** | Event management | Not deployed | ⏸️ Disabled | `pretix-version` |

### Application Integration Features

**CI/CD Integration:**

- **GitHub Actions Secrets**: Automatic ACR credentials injection
- **Workflow Triggers**: Automated builds on application changes
- **Image Updates**: Flux image automation for latest image deployment

**Common Application Features:**

- **FortiWeb VIP**: Dedicated public IP and WAF protection
- **TLS Certificates**: Automated cert-manager integration
- **Authentication**: htpasswd-based basic authentication where applicable
- **Monitoring**: Lacework security monitoring
- **DNS**: Automatic CNAME record management

## 🔧 Terraform Best Practices Implemented

- ✅ **Provider Versioning**: Specific provider versions pinned
- ✅ **Variable Validation**: Input validation where applicable
- ✅ **Sensitive Data**: Proper sensitive variable handling
- ✅ **Resource Tagging**: Consistent tagging strategy
- ✅ **State Management**: Remote backend configuration ready

## 🔍 Troubleshooting Guide

### Common Issues and Solutions

#### Infrastructure Deployment Issues

**Issue**: Terraform plan fails with provider authentication errors
```bash
# Solution: Ensure Azure CLI is authenticated
az login
az account set --subscription "your-subscription-id"
```

**Issue**: NVA deployment fails due to marketplace agreement
```bash
# Solution: Accept marketplace terms
az vm image terms accept --urn "fortinet:fortinet_fortiweb-vm_v5:fortinet_fw-vm:latest"
```

**Issue**: AKS cluster creation timeout
```bash
# Check resource provider registration
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.OperationalInsights
```

#### Kubernetes/GitOps Issues

**Issue**: Flux GitOps synchronization failures
```bash
# Check Flux system status
kubectl get pods -n flux-system
kubectl logs -n flux-system -l app=source-controller

# Force reconciliation
flux reconcile source git infrastructure
```

**Issue**: Certificate Manager fails to issue certificates
```bash
# Check cert-manager status
kubectl get clusterissuer
kubectl describe certificaterequest -n cert-manager

# Verify Azure DNS permissions
kubectl logs -n cert-manager deploy/cert-manager
```

**Issue**: Application pods in CrashLoopBackOff
```bash
# Check pod logs and events
kubectl logs -n <namespace> <pod-name> -f
kubectl describe pod -n <namespace> <pod-name>

# Check resource limits and requests
kubectl top pods -n <namespace>
```

#### Network Connectivity Issues

**Issue**: FortiWeb VIP not accessible from internet
```bash
# Check Network Security Group rules
az network nsg rule list --resource-group <rg> --nsg-name <nsg>

# Verify public IP association
az network public-ip show --resource-group <rg> --name <pip-name>
```

**Issue**: Pod-to-pod communication failures
```bash
# Check network policies
kubectl get networkpolicies -A
kubectl describe networkpolicy -n <namespace> <policy-name>

# Test connectivity from within cluster
kubectl run test-pod --image=busybox -it --rm -- /bin/sh
```

#### Security and Monitoring

**Issue**: Lacework agent not reporting data
```bash
# Check agent deployment status
kubectl get pods -n lacework-agent
kubectl logs -n lacework-agent daemonset/lacework-agent

# Verify Lacework configuration
kubectl get secret -n lacework-agent lacework-agent-config -o yaml
```

**Issue**: GitHub Actions workflow failures
```bash
# Check workflow logs in GitHub Actions tab
# Common solutions:
# 1. Verify AZURE_CREDENTIALS secret is valid
# 2. Check Terraform state file access
# 3. Validate Azure resource permissions
```

### Performance Optimization

#### Resource Right-Sizing

```bash
# Monitor resource usage
kubectl top nodes
kubectl top pods -A --sort-by=cpu
kubectl top pods -A --sort-by=memory

# Check resource requests vs usage
kubectl describe nodes | grep -A 5 "Allocated resources"
```

#### Storage Optimization

```bash
# Check persistent volume usage
kubectl get pv,pvc -A
df -h # On cluster nodes

# Clean up unused images (on nodes)
crictl images
crictl rmi <unused-image-id>
```

### Disaster Recovery Testing

#### Backup Verification

```bash
# Test AKS cluster backup (if enabled)
az aks show --resource-group <rg> --name <cluster-name> --query backupConfig

# Verify critical application data backups
kubectl exec -n <namespace> <pod-name> -- backup-command
```

#### Failover Testing

```bash
# Test NVA failover (when HA is implemented)
# 1. Stop primary NVA instance
# 2. Verify traffic fails over to secondary
# 3. Monitor application availability

# Test application pod failover
kubectl delete pod -n <namespace> <pod-name>
kubectl get pods -n <namespace> -w
```

## 🚨 Action Required

**Immediate Priority**: Address the single point of failure in the NVA deployment by implementing the high availability recommendations outlined above. This is critical for production workloads.

**Next Steps**:

1. Review and approve HA implementation plan
2. Plan maintenance window for NVA upgrades
3. Implement monitoring and alerting for new HA setup
4. Update disaster recovery procedures

## 📚 Additional Resources

## 🔐 Certificate Management & Renewal with cert-manager (cmctl)

This infrastructure uses cert-manager for automated TLS certificate management. In some cases, you may need to manually inspect, troubleshoot, or renew certificates using the `cmctl` CLI and Kubernetes tools.

### Common Tasks

#### 1. List Certificates in a Namespace
```bash
kubectl get certificates -n <namespace>
# Example:
kubectl get certificates -n docs
```

#### 2. Inspect Certificate Status with cmctl
```bash
cmctl status certificate <certificate-name> --namespace <namespace>
# Example:
cmctl status certificate docs-tls --namespace docs
```

#### 3. Force Certificate Renewal
```bash
cmctl renew <certificate-name> --namespace <namespace>
# Example:
cmctl renew docs-tls --namespace docs
```

#### 4. Check cert-manager Controller Logs
```bash
kubectl logs -n cert-manager deploy/cert-manager
```

#### 5. Troubleshoot Certificate Events
```bash
kubectl describe certificate <certificate-name> -n <namespace>
# Example:
kubectl describe certificate docs-tls -n docs
```

### Example: Full Certificate Renewal Workflow

```bash
# 1. List certificates in the docs namespace
kubectl get certificates -n docs

# 2. Check the status of the docs-tls certificate
cmctl status certificate docs-tls --namespace docs

# 3. Force renewal if needed
cmctl renew docs-tls --namespace docs

# 4. Confirm renewal and check new validity dates
cmctl status certificate docs-tls --namespace docs

# 5. If issues, inspect events and logs
kubectl describe certificate docs-tls -n docs
kubectl logs -n cert-manager deploy/cert-manager
```

### Notes
- `cmctl` is the official CLI for cert-manager. It complements kubectl for certificate lifecycle management.
- Use `kubectl` for general resource inspection and event troubleshooting.
- Always check certificate events and cert-manager logs if renewal does not succeed.
- For more, see: [cert-manager documentation](https://cert-manager.io/docs/), [cmctl usage](https://cert-manager.io/docs/usage/cmctl/)

- [Azure NVA High Availability Guide](https://learn.microsoft.com/en-us/azure/architecture/networking/guide/network-virtual-appliance-high-availability)
- [FortiWeb Azure Deployment Guide](https://docs.fortinet.com/document/fortiweb-public-cloud)
- [AKS Best Practices](https://learn.microsoft.com/en-us/azure/aks/best-practices)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Flux GitOps Documentation](https://fluxcd.io/flux/concepts/)
- [Lacework Kubernetes Monitoring](https://docs.lacework.com/onboarding/kubernetes)
- **External Tools**: Security scanning tools (`tfsec`, `trivy`, `checkov`) recommended.

## Key Files

- `cloud-init/` — VM initialization scripts
- `spoke-k8s_application-*.tf` — Application deployments
- `hub-network.tf`, `spoke-network.tf` — Network definitions
- `.github/instructions.md` — Terraform conventions
- `.github/workflows/infrastructure.yml` — CI/CD pipeline

## Example: Adding a New Application

1. Create `spoke-k8s_application-<name>.tf` for the new app.
2. Define resources using existing patterns.
3. Update variables and outputs as needed.
4. Commit and push to `main` to trigger deployment.

## Cloud-Init Troubleshooting

### CLOUDSHELL

```bash
sudo cloud-init schema --system
```

## References

- https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#linux-distributions
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 2.5 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.38 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.3 |
| <a name="requirement_flux"></a> [flux](#requirement\_flux) | ~> 1.6 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 6.6 |
| <a name="requirement_htpasswd"></a> [htpasswd](#requirement\_htpasswd) | ~> 1.2 |
| <a name="requirement_http"></a> [http](#requirement\_http) | ~> 3.5 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.38 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.7 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | 2.5.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.39.0 |
| <a name="provider_github"></a> [github](#provider\_github) | 6.6.0 |
| <a name="provider_htpasswd"></a> [htpasswd](#provider\_htpasswd) | 1.2.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azapi_resource.cloudshell_ssh_public_key](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource_action.cloudshell_ssh_public_key_gen](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource_action) | resource |
| [azurerm_application_insights.platform_insights](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |
| [azurerm_availability_set.hub_nva_availability_set](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/availability_set) | resource |
| [azurerm_container_registry.container_registry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry) | resource |
| [azurerm_dns_cname_record.app1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_cname_record.app2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_cname_record.app3](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_cname_record.app4](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_cname_record.app5](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_cname_record.app6](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_cname_record.app7](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_cname_record.artifacts](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_cname_record.cloudshell_public_ip_dns](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_cname_record.docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_cname_record.dvwa](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_cname_record.extractor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_cname_record.hub_nva](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_cname_record.ollama](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_cname_record.pretix](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_zone.dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_zone) | resource |
| [azurerm_federated_identity_credential.cert-manager_federated_identity_credential](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential) | resource |
| [azurerm_kubernetes_cluster.kubernetes_cluster](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_kubernetes_cluster_extension.flux_extension](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_extension) | resource |
| [azurerm_kubernetes_cluster_node_pool.cpu_node_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) | resource |
| [azurerm_kubernetes_cluster_node_pool.gpu_node_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) | resource |
| [azurerm_kubernetes_flux_configuration.artifacts](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_flux_configuration) | resource |
| [azurerm_kubernetes_flux_configuration.docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_flux_configuration) | resource |
| [azurerm_kubernetes_flux_configuration.dvwa](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_flux_configuration) | resource |
| [azurerm_kubernetes_flux_configuration.extractor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_flux_configuration) | resource |
| [azurerm_kubernetes_flux_configuration.gpu-operator](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_flux_configuration) | resource |
| [azurerm_kubernetes_flux_configuration.infrastructure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_flux_configuration) | resource |
| [azurerm_kubernetes_flux_configuration.ollama](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_flux_configuration) | resource |
| [azurerm_kubernetes_flux_configuration.pretix](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_flux_configuration) | resource |
| [azurerm_kubernetes_flux_configuration.video](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_flux_configuration) | resource |
| [azurerm_lb.hub_nva_lb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb) | resource |
| [azurerm_lb_backend_address_pool.hub_nva_backend_pools](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_probe.hub_nva_health_probe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) | resource |
| [azurerm_lb_rule.hub_nva_app_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) | resource |
| [azurerm_linux_virtual_machine.cloudshell_vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_linux_virtual_machine.hub_nva_instances](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_linux_virtual_machine.hub_nva_virtual_machine](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_log_analytics_saved_search.app_error_analysis](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_saved_search) | resource |
| [azurerm_log_analytics_saved_search.fortiweb_performance](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_saved_search) | resource |
| [azurerm_log_analytics_saved_search.network_traffic_analysis](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_saved_search) | resource |
| [azurerm_log_analytics_workspace.log_analytics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_log_analytics_workspace.platform_workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_managed_disk.cloudshell_docker_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | resource |
| [azurerm_managed_disk.cloudshell_home_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | resource |
| [azurerm_managed_disk.cloudshell_ollama_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | resource |
| [azurerm_monitor_action_group.critical_alerts](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group) | resource |
| [azurerm_monitor_action_group.warning_alerts](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group) | resource |
| [azurerm_monitor_diagnostic_setting.hub_nva_lb_diagnostics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_metric_alert.aks_node_cpu_alert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.aks_pod_restart_alert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.app_response_time_alert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.fortiweb_cpu_alert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.fortiweb_memory_alert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.hub_nva_health_alert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_network_interface.cloudshell_nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.hub_nva_external_interfaces](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.hub_nva_external_network_interface](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.hub_nva_internal_interfaces](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.hub_nva_internal_network_interface](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_backend_address_pool_association.hub_nva_lb_associations](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_backend_address_pool_association) | resource |
| [azurerm_network_interface_security_group_association.cloudshell_nic_nsg_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_security_group.cloudshell_nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.hub_external_network_security_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.hub_internal_network_security_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.spoke_network_security_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_watcher_flow_log.hub_nsg_flow_log](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher_flow_log) | resource |
| [azurerm_public_ip.cloudshell_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.hub_nva_ha_management_public_ips](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.hub_nva_management_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.hub_nva_vip_artifacts_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.hub_nva_vip_docs_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.hub_nva_vip_dvwa_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.hub_nva_vip_extractor_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.hub_nva_vip_ollama_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.hub_nva_vip_pretix_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.hub_nva_vip_video_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.azure_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.acr_role_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.cert-manager_role_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.kubernetes_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.route_table_network_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_route_table.hub_route_table](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_route_table.spoke_route_table](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_storage_account.cloudshell_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_account.nsg_flow_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_subnet.cloudshell_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.hub_external_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.hub_internal_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.spoke_aks_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.spoke_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.hub_external_subnet_nsg_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.hub_internal_subnet_nsg_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.spoke_subnet_nsg_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_route_table_association.hub_external_route_table_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.hub_internal_route_table_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.spoke_route_table_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_user_assigned_identity.cert-manager](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_user_assigned_identity.my_identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_virtual_machine_data_disk_attachment.cloudshell_docker_disk_attachment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_data_disk_attachment.cloudshell_home_disk_attachment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_data_disk_attachment.cloudshell_ollama_disk_attachment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_network.cloudshell_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_virtual_network.hub_virtual_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_virtual_network.spoke_virtual_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_virtual_network_peering.hub_to_spoke_virtual_network_peering](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) | resource |
| [azurerm_virtual_network_peering.spoke_to_hub_virtual_network_peering](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) | resource |
| [github_actions_secret.DOCS_BUILDER_ACR_LOGIN_SERVER](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [github_actions_secret.MANIFESTS_APPLICATIONS_ACR_LOGIN_SERVER](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [htpasswd_password.hash](https://registry.terraform.io/providers/loafoe/htpasswd/latest/docs/resources/password) | resource |
| [kubernetes_namespace.artifacts](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.cert-manager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.docs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.dvwa](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.extractor](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.ingress-helper](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.lacework-agent](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.ollama](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.pretix](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.video](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.artifacts_fortiweb_login_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.cert-manager_fortiweb_login_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.clusterissuer](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.docs_fortiweb_login_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.dvwa_fortiweb_login_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.extractor_fortiweb_login_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.htpasswd_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.ingress-helper_fortiweb_login_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.lacework_agent_token](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.ollama_fortiweb_login_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.pretix_fortiweb_login_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.video_fortiweb_login_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [null_resource.marketplace_agreement](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.trigger_artifacts-version_workflow](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.trigger_docs_builder_workflow](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.trigger_ollama-version_workflow](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_id.random_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_pet.cloudshell_ssh_key_name](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [random_string.acr_name](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_string.vm_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_private_key.cloudshell_host_ecdsa](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.cloudshell_host_ed25519](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.cloudshell_host_rsa](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.private_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.self_signed_cert](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_network_watcher.network_watcher](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_watcher) | data source |
| [azurerm_public_ip.hub_nva_management_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip) | data source |
| [azurerm_public_ip.hub_nva_vip_artifacts_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip) | data source |
| [azurerm_public_ip.hub_nva_vip_docs_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip) | data source |
| [azurerm_public_ip.hub_nva_vip_dvwa_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip) | data source |
| [azurerm_public_ip.hub_nva_vip_extractor_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip) | data source |
| [azurerm_public_ip.hub_nva_vip_ollama_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip) | data source |
| [azurerm_public_ip.hub_nva_vip_pretix_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip) | data source |
| [azurerm_user_assigned_identity.cert_manager_data](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/user_assigned_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_artifacts"></a> [application\_artifacts](#input\_application\_artifacts) | Deploy Artifacts application | `bool` | `true` | no |
| <a name="input_application_docs"></a> [application\_docs](#input\_application\_docs) | Deploy Docs application | `bool` | `true` | no |
| <a name="input_application_dvwa"></a> [application\_dvwa](#input\_application\_dvwa) | Deploy DVWA (Damn Vulnerable Web Application) | `bool` | `true` | no |
| <a name="input_application_extractor"></a> [application\_extractor](#input\_application\_extractor) | Deploy Extractor application | `bool` | `true` | no |
| <a name="input_application_ollama"></a> [application\_ollama](#input\_application\_ollama) | Deploy Ollama application | `bool` | `true` | no |
| <a name="input_application_signup"></a> [application\_signup](#input\_application\_signup) | Deploy Signup application | `bool` | `false` | no |
| <a name="input_application_video"></a> [application\_video](#input\_application\_video) | Deploy Video application | `bool` | `true` | no |
| <a name="input_arm_subscription_id"></a> [arm\_subscription\_id](#input\_arm\_subscription\_id) | Azure Subscription ID | `string` | n/a | yes |
| <a name="input_brave_api_key"></a> [brave\_api\_key](#input\_brave\_api\_key) | API key for Brave Search integration in CloudShell | `string` | n/a | yes |
| <a name="input_cloudshell"></a> [cloudshell](#input\_cloudshell) | Deploy CloudShell VM | `bool` | `false` | no |
| <a name="input_cloudshell_admin_username"></a> [cloudshell\_admin\_username](#input\_cloudshell\_admin\_username) | The username for the Cloud Shell administrator. | `string` | `"ubuntu"` | no |
| <a name="input_cloudshell_auth_fqdn"></a> [cloudshell\_auth\_fqdn](#input\_cloudshell\_auth\_fqdn) | FQDN for CloudShell instance (used for Entra ID redirect URIs) | `string` | `"cloudshell.example.com"` | no |
| <a name="input_cloudshell_directory_client_id"></a> [cloudshell\_directory\_client\_id](#input\_cloudshell\_directory\_client\_id) | The client ID of the Azure Active Directory application. | `string` | n/a | yes |
| <a name="input_cloudshell_directory_tenant_id"></a> [cloudshell\_directory\_tenant\_id](#input\_cloudshell\_directory\_tenant\_id) | The tenant ID of the Azure Active Directory. | `string` | n/a | yes |
| <a name="input_cpu_alert_threshold"></a> [cpu\_alert\_threshold](#input\_cpu\_alert\_threshold) | CPU utilization percentage threshold for alerts | `number` | `85` | no |
| <a name="input_dashboard_time_range"></a> [dashboard\_time\_range](#input\_dashboard\_time\_range) | Default time range for dashboard widgets | `string` | `"PT1H"` | no |
| <a name="input_dns_zone"></a> [dns\_zone](#input\_dns\_zone) | DNS Zone for the deployment | `string` | `"example.com"` | no |
| <a name="input_docs_builder_repo_name"></a> [docs\_builder\_repo\_name](#input\_docs\_builder\_repo\_name) | Name of the docs builder repository | `string` | `"docs-builder"` | no |
| <a name="input_enable_application_insights"></a> [enable\_application\_insights](#input\_enable\_application\_insights) | Enable Application Insights for application monitoring | `bool` | `true` | no |
| <a name="input_enable_container_insights"></a> [enable\_container\_insights](#input\_enable\_container\_insights) | Enable Container Insights for AKS monitoring | `bool` | `true` | no |
| <a name="input_enable_cost_alerts"></a> [enable\_cost\_alerts](#input\_enable\_cost\_alerts) | Enable cost-based alerts for monitoring services | `bool` | `true` | no |
| <a name="input_enable_custom_dashboard"></a> [enable\_custom\_dashboard](#input\_enable\_custom\_dashboard) | Enable creation of custom monitoring dashboard | `bool` | `true` | no |
| <a name="input_enable_network_flow_logs"></a> [enable\_network\_flow\_logs](#input\_enable\_network\_flow\_logs) | Enable Network Security Group flow logs and traffic analytics | `bool` | `true` | no |
| <a name="input_enable_vm_insights"></a> [enable\_vm\_insights](#input\_enable\_vm\_insights) | Enable VM Insights for virtual machine monitoring | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment (e.g., dev, staging, prod) | `string` | `"dev"` | no |
| <a name="input_forticnapp_account"></a> [forticnapp\_account](#input\_forticnapp\_account) | The FortiCnapp account name. | `string` | n/a | yes |
| <a name="input_forticnapp_api_key"></a> [forticnapp\_api\_key](#input\_forticnapp\_api\_key) | The FortiCnapp api\_key. | `string` | n/a | yes |
| <a name="input_forticnapp_api_secret"></a> [forticnapp\_api\_secret](#input\_forticnapp\_api\_secret) | The FortiCnapp api\_secret. | `string` | n/a | yes |
| <a name="input_forticnapp_subaccount"></a> [forticnapp\_subaccount](#input\_forticnapp\_subaccount) | The FortiCnapp subaccount name. | `string` | n/a | yes |
| <a name="input_github_org"></a> [github\_org](#input\_github\_org) | GitHub organization name | `string` | n/a | yes |
| <a name="input_github_token"></a> [github\_token](#input\_github\_token) | GitHub token for authenticating to the repository | `string` | n/a | yes |
| <a name="input_gpu_node_pool"></a> [gpu\_node\_pool](#input\_gpu\_node\_pool) | Set to true to enable GPU workloads | `bool` | `false` | no |
| <a name="input_htpasswd"></a> [htpasswd](#input\_htpasswd) | Password for HTTP authentication | `string` | n/a | yes |
| <a name="input_htusername"></a> [htusername](#input\_htusername) | Username for HTTP authentication | `string` | n/a | yes |
| <a name="input_hub_external_subnet_gateway"></a> [hub\_external\_subnet\_gateway](#input\_hub\_external\_subnet\_gateway) | Azure gateway IP address to the Internet | `string` | `"10.0.0.1"` | no |
| <a name="input_hub_external_subnet_name"></a> [hub\_external\_subnet\_name](#input\_hub\_external\_subnet\_name) | External Subnet Name. | `string` | `"hub-external_subnet"` | no |
| <a name="input_hub_external_subnet_prefix"></a> [hub\_external\_subnet\_prefix](#input\_hub\_external\_subnet\_prefix) | External Subnet Prefix. | `string` | `"10.0.0.0/27"` | no |
| <a name="input_hub_internal_subnet_address_prefix"></a> [hub\_internal\_subnet\_address\_prefix](#input\_hub\_internal\_subnet\_address\_prefix) | Hub Internal Subnet Address prefix for NVA backend connectivity | `string` | `"10.0.1.0/26"` | no |
| <a name="input_hub_internal_subnet_name"></a> [hub\_internal\_subnet\_name](#input\_hub\_internal\_subnet\_name) | Hub Subnet Name. | `string` | `"hub-internal_subnet"` | no |
| <a name="input_hub_internal_subnet_prefix"></a> [hub\_internal\_subnet\_prefix](#input\_hub\_internal\_subnet\_prefix) | Hub Subnet Prefix. | `string` | `"10.0.0.32/27"` | no |
| <a name="input_hub_nva_admin_username"></a> [hub\_nva\_admin\_username](#input\_hub\_nva\_admin\_username) | Admin username for FortiWeb NVA instances | `string` | `"azureadmin"` | no |
| <a name="input_hub_nva_availability_zones"></a> [hub\_nva\_availability\_zones](#input\_hub\_nva\_availability\_zones) | Availability zones for FortiWeb instance deployment | `list(string)` | <pre>[<br/>  "1",<br/>  "2"<br/>]</pre> | no |
| <a name="input_hub_nva_cluster_sync_timeout"></a> [hub\_nva\_cluster\_sync\_timeout](#input\_hub\_nva\_cluster\_sync\_timeout) | Timeout in seconds for HA cluster synchronization | `number` | `300` | no |
| <a name="input_hub_nva_gateway"></a> [hub\_nva\_gateway](#input\_hub\_nva\_gateway) | Hub NVA Gateway IP Address | `string` | `"10.0.0.37"` | no |
| <a name="input_hub_nva_health_check_interval"></a> [hub\_nva\_health\_check\_interval](#input\_hub\_nva\_health\_check\_interval) | Health check interval in seconds for load balancer probes | `number` | `30` | no |
| <a name="input_hub_nva_high_availability"></a> [hub\_nva\_high\_availability](#input\_hub\_nva\_high\_availability) | Enable high availability deployment with multiple FortiWeb instances across availability zones | `bool` | `false` | no |
| <a name="input_hub_nva_image"></a> [hub\_nva\_image](#input\_hub\_nva\_image) | NVA image product | `string` | `"fortiweb"` | no |
| <a name="input_hub_nva_instance_size_development"></a> [hub\_nva\_instance\_size\_development](#input\_hub\_nva\_instance\_size\_development) | VM size for FortiWeb instances in development environment | `string` | `"Standard_F2s_v2"` | no |
| <a name="input_hub_nva_instance_size_production"></a> [hub\_nva\_instance\_size\_production](#input\_hub\_nva\_instance\_size\_production) | VM size for FortiWeb instances in production environment | `string` | `"Standard_F4s_v2"` | no |
| <a name="input_hub_nva_lb_sku_tier"></a> [hub\_nva\_lb\_sku\_tier](#input\_hub\_nva\_lb\_sku\_tier) | Load Balancer SKU tier (Regional or Global) | `string` | `"Regional"` | no |
| <a name="input_hub_nva_management_ip"></a> [hub\_nva\_management\_ip](#input\_hub\_nva\_management\_ip) | Hub NVA Management IP Address | `string` | `"10.0.0.4"` | no |
| <a name="input_hub_nva_os_disk_size"></a> [hub\_nva\_os\_disk\_size](#input\_hub\_nva\_os\_disk\_size) | OS disk size in GB for FortiWeb instances | `number` | `64` | no |
| <a name="input_hub_nva_os_disk_type"></a> [hub\_nva\_os\_disk\_type](#input\_hub\_nva\_os\_disk\_type) | OS disk storage type for FortiWeb instances | `string` | `"Premium_LRS"` | no |
| <a name="input_hub_nva_password"></a> [hub\_nva\_password](#input\_hub\_nva\_password) | Password for Hub NVA device | `string` | n/a | yes |
| <a name="input_hub_nva_username"></a> [hub\_nva\_username](#input\_hub\_nva\_username) | Username for Hub NVA device | `string` | n/a | yes |
| <a name="input_hub_nva_vip_artifacts"></a> [hub\_nva\_vip\_artifacts](#input\_hub\_nva\_vip\_artifacts) | Hub NVA Gateway Virtual IP Address for Artifacts | `string` | `"10.0.0.9"` | no |
| <a name="input_hub_nva_vip_docs"></a> [hub\_nva\_vip\_docs](#input\_hub\_nva\_vip\_docs) | Hub NVA Gateway Virtual IP Address for Docs | `string` | `"10.0.0.5"` | no |
| <a name="input_hub_nva_vip_dvwa"></a> [hub\_nva\_vip\_dvwa](#input\_hub\_nva\_vip\_dvwa) | Hub NVA Gateway Virtual IP Address for DVWA | `string` | `"10.0.0.6"` | no |
| <a name="input_hub_nva_vip_extractor"></a> [hub\_nva\_vip\_extractor](#input\_hub\_nva\_vip\_extractor) | Hub NVA Gateway Virtual IP Address for extractor | `string` | `"10.0.0.10"` | no |
| <a name="input_hub_nva_vip_ollama"></a> [hub\_nva\_vip\_ollama](#input\_hub\_nva\_vip\_ollama) | Hub NVA Gateway Virtual IP Address for Ollama | `string` | `"10.0.0.7"` | no |
| <a name="input_hub_nva_vip_video"></a> [hub\_nva\_vip\_video](#input\_hub\_nva\_vip\_video) | Hub NVA Gateway Virtual IP Address for Video | `string` | `"10.0.0.8"` | no |
| <a name="input_hub_virtual_network_address_prefix"></a> [hub\_virtual\_network\_address\_prefix](#input\_hub\_virtual\_network\_address\_prefix) | Hub Virtual Network Address prefix | `string` | `"10.0.0.0/24"` | no |
| <a name="input_letsencrypt_url"></a> [letsencrypt\_url](#input\_letsencrypt\_url) | Production or staging Let's Encrypt URL | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region for resource deployment | `string` | `"eastus"` | no |
| <a name="input_log_analytics_daily_quota_gb"></a> [log\_analytics\_daily\_quota\_gb](#input\_log\_analytics\_daily\_quota\_gb) | Daily ingestion quota in GB for Log Analytics workspace | `number` | `5` | no |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Log Analytics Workspace ID for diagnostic settings and monitoring | `string` | `""` | no |
| <a name="input_lw_agent_token"></a> [lw\_agent\_token](#input\_lw\_agent\_token) | Lacework agent token for security monitoring | `string` | n/a | yes |
| <a name="input_management_public_ip"></a> [management\_public\_ip](#input\_management\_public\_ip) | Whether to create a public IP for management access. Set to true in production via tfvars or CI/CD. | `bool` | `false` | no |
| <a name="input_manifests_applications_repo_name"></a> [manifests\_applications\_repo\_name](#input\_manifests\_applications\_repo\_name) | Name of the applications manifest repository | `string` | n/a | yes |
| <a name="input_manifests_applications_ssh_private_key"></a> [manifests\_applications\_ssh\_private\_key](#input\_manifests\_applications\_ssh\_private\_key) | SSH private key for applications manifest repository authentication | `string` | n/a | yes |
| <a name="input_manifests_infrastructure_repo_name"></a> [manifests\_infrastructure\_repo\_name](#input\_manifests\_infrastructure\_repo\_name) | Name of the infrastructure manifest repository | `string` | n/a | yes |
| <a name="input_manifests_infrastructure_ssh_private_key"></a> [manifests\_infrastructure\_ssh\_private\_key](#input\_manifests\_infrastructure\_ssh\_private\_key) | SSH private key for infrastructure manifest repository authentication | `string` | n/a | yes |
| <a name="input_memory_alert_threshold_mb"></a> [memory\_alert\_threshold\_mb](#input\_memory\_alert\_threshold\_mb) | Available memory threshold in MB for alerts | `number` | `512` | no |
| <a name="input_monitoring_budget_amount"></a> [monitoring\_budget\_amount](#input\_monitoring\_budget\_amount) | Monthly budget amount in USD for monitoring costs | `number` | `100` | no |
| <a name="input_monitoring_retention_days"></a> [monitoring\_retention\_days](#input\_monitoring\_retention\_days) | Retention period in days for monitoring data | `number` | `30` | no |
| <a name="input_name"></a> [name](#input\_name) | Full name of the owner for resource tagging | `string` | n/a | yes |
| <a name="input_owner_email"></a> [owner\_email](#input\_owner\_email) | Email address for use with Owner tag | `string` | n/a | yes |
| <a name="input_perplexity_api_key"></a> [perplexity\_api\_key](#input\_perplexity\_api\_key) | API key for Perplexity AI integration in CloudShell | `string` | n/a | yes |
| <a name="input_production_environment"></a> [production\_environment](#input\_production\_environment) | Whether this is a production environment (affects resource sizing and configuration) | `bool` | `true` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for tagging and resource naming | `string` | n/a | yes |
| <a name="input_response_time_alert_threshold_ms"></a> [response\_time\_alert\_threshold\_ms](#input\_response\_time\_alert\_threshold\_ms) | Application response time threshold in milliseconds for alerts | `number` | `5000` | no |
| <a name="input_spoke_aks_node_ip"></a> [spoke\_aks\_node\_ip](#input\_spoke\_aks\_node\_ip) | Spoke Container Server IP Address | `string` | `"10.1.1.4"` | no |
| <a name="input_spoke_aks_pod_cidr"></a> [spoke\_aks\_pod\_cidr](#input\_spoke\_aks\_pod\_cidr) | Spoke k8s pod cidr. | `string` | `"10.244.0.0/16"` | no |
| <a name="input_spoke_aks_subnet_name"></a> [spoke\_aks\_subnet\_name](#input\_spoke\_aks\_subnet\_name) | Spoke aks Subnet Name. | `string` | `"spoke-aks-subnet"` | no |
| <a name="input_spoke_aks_subnet_prefix"></a> [spoke\_aks\_subnet\_prefix](#input\_spoke\_aks\_subnet\_prefix) | Spoke Pod Subnet Prefix. | `string` | `"10.1.2.0/24"` | no |
| <a name="input_spoke_check_internet_up_ip"></a> [spoke\_check\_internet\_up\_ip](#input\_spoke\_check\_internet\_up\_ip) | Spoke Container Server Checks the Internet at this IP Address | `string` | `"8.8.8.8"` | no |
| <a name="input_spoke_subnet_name"></a> [spoke\_subnet\_name](#input\_spoke\_subnet\_name) | Spoke Subnet Name. | `string` | `"spoke_subnet"` | no |
| <a name="input_spoke_subnet_prefix"></a> [spoke\_subnet\_prefix](#input\_spoke\_subnet\_prefix) | Spoke Subnet Prefix. | `string` | `"10.1.1.0/24"` | no |
| <a name="input_spoke_virtual_network_address_prefix"></a> [spoke\_virtual\_network\_address\_prefix](#input\_spoke\_virtual\_network\_address\_prefix) | Spoke Virtual Network Address prefix. | `string` | `"10.1.0.0/16"` | no |
| <a name="input_teams_webhook_url"></a> [teams\_webhook\_url](#input\_teams\_webhook\_url) | Microsoft Teams webhook URL for critical alerts | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dns_zone_name"></a> [dns\_zone\_name](#output\_dns\_zone\_name) | Name of the DNS zone |
| <a name="output_dns_zone_name_servers"></a> [dns\_zone\_name\_servers](#output\_dns\_zone\_name\_servers) | Name servers for the DNS zone |
| <a name="output_hub_nva_management_fqdn"></a> [hub\_nva\_management\_fqdn](#output\_hub\_nva\_management\_fqdn) | FQDN for NVA management access (if enabled) |
| <a name="output_hub_nva_management_public_ip"></a> [hub\_nva\_management\_public\_ip](#output\_hub\_nva\_management\_public\_ip) | Public IP address for NVA management (if enabled) |
| <a name="output_hub_virtual_network_id"></a> [hub\_virtual\_network\_id](#output\_hub\_virtual\_network\_id) | ID of the hub virtual network |
| <a name="output_kube_config"></a> [kube\_config](#output\_kube\_config) | Kubernetes cluster configuration |
| <a name="output_kubernetes_cluster_fqdn"></a> [kubernetes\_cluster\_fqdn](#output\_kubernetes\_cluster\_fqdn) | FQDN of the AKS cluster |
| <a name="output_kubernetes_cluster_name"></a> [kubernetes\_cluster\_name](#output\_kubernetes\_cluster\_name) | Name of the AKS cluster |
| <a name="output_resource_group_location"></a> [resource\_group\_location](#output\_resource\_group\_location) | Location of the created resource group |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the created resource group |
| <a name="output_spoke_virtual_network_id"></a> [spoke\_virtual\_network\_id](#output\_spoke\_virtual\_network\_id) | ID of the spoke virtual network |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
