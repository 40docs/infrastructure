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

### Local Development
```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate
terraform fmt

# Plan changes (use variables from GitHub secrets)
terraform plan -out=tfplan

# Apply (typically done via CI/CD)
terraform apply tfplan
```

### CI/CD Pipeline
1. **Trigger**: Changes to `*.tf` or `cloud-init/*` files
2. **Validation**: Format checking, validation, and security scanning
3. **Planning**: Terraform plan with approval gates
4. **Deployment**: Automated apply with state management
5. **Verification**: Post-deployment health checks

## 📁 File Structure

```
├── hub-nva.tf                           # FortiWeb NVA configuration
├── hub-network.tf                       # Hub network resources
├── spoke-network.tf                     # Spoke network resources
├── spoke-k8s_cluster.tf                 # AKS cluster configuration
├── spoke-k8s_application-*.tf           # Application deployments
├── spoke-k8s_infrastructure-*.tf        # Infrastructure services
├── variables.tf                         # Input variables
├── terraform.tf                         # Provider configuration
├── locals.tf                           # Local values and VM images
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

## 🚀 Current Applications

| Application | Purpose | Namespace | Status |
|-------------|---------|-----------|--------|
| **docs** | Documentation hosting | `docs` | ✅ Running |
| **dvwa** | Security testing | `dvwa` | ✅ Running |
| **extractor** | Data processing | `extractor` | ✅ Running |
| **ollama** | AI/ML workloads | Not deployed | ⏸️ Disabled |
| **artifacts** | Build artifacts | Not deployed | ⏸️ Disabled |
| **video** | Media streaming | Not deployed | ⏸️ Disabled |
| **pretix** | Event management | Not deployed | ⏸️ Disabled |

## 🔧 Terraform Best Practices Implemented

- ✅ **Provider Versioning**: Specific provider versions pinned
- ✅ **Variable Validation**: Input validation where applicable
- ✅ **Sensitive Data**: Proper sensitive variable handling
- ✅ **Resource Tagging**: Consistent tagging strategy
- ✅ **State Management**: Remote backend configuration ready

## 🚨 Action Required

**Immediate Priority**: Address the single point of failure in the NVA deployment by implementing the high availability recommendations outlined above. This is critical for production workloads.

**Next Steps**:
1. Review and approve HA implementation plan
2. Plan maintenance window for NVA upgrades
3. Implement monitoring and alerting for new HA setup
4. Update disaster recovery procedures

## 📚 Additional Resources

- [Azure NVA High Availability Guide](https://learn.microsoft.com/en-us/azure/architecture/networking/guide/network-virtual-appliance-high-availability)
- [FortiWeb Azure Deployment Guide](https://docs.fortinet.com/document/fortiweb-public-cloud)
- [AKS Best Practices](https://learn.microsoft.com/en-us/azure/aks/best-practices)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
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
