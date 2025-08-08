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
