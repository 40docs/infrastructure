# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the **infrastructure** repository within the 40docs platform - a Terraform-based Infrastructure as Code (IaC) solution that deploys Azure resources including hub-spoke network topology with FortiWeb NVA and Azure Kubernetes Service (AKS) cluster with GitOps capabilities.

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

### Terraform Validation Errors
```bash
# Check for resource reference errors
terraform validate

# Common issue: Variable naming inconsistencies
# Solution: Ensure all variables use snake_case format
```

### Azure Provider Authentication
```bash
# Re-authenticate if local testing needed
az login
az account set --subscription "subscription-id"

# Accept FortiWeb marketplace terms
az vm image terms accept --urn "fortinet:fortinet_fortiweb-vm_v5:fortinet_fw-vm:latest"
```

### GitHub Actions Failures
Common causes and solutions:
1. **Invalid Azure credentials**: Verify `AZURE_CREDENTIALS` secret
2. **State file access**: Check Azure Storage Account permissions
3. **Variable validation**: Ensure all required variables are set
4. **Resource quotas**: Verify Azure subscription limits

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