# Terraform Modules for 40docs Infrastructure

This directory contains modular Terraform configurations to improve reusability, maintainability, and testing of the 40docs infrastructure.

## Module Structure

```
modules/
├── network-hub-spoke/          # Hub-spoke network topology
├── fortiweb-ha/               # High availability FortiWeb deployment
├── aks-cluster/              # Azure Kubernetes Service cluster
├── application-deployment/    # Standard application deployment pattern
├── monitoring/               # Monitoring and alerting configuration
└── certificate-management/   # TLS certificate automation
```

## Module Standards

### Input Variables
- All variables include type, description, and validation rules
- Sensitive variables marked with `sensitive = true`
- Default values provided for optional parameters
- Validation rules enforce business logic and security constraints

### Outputs
- Expose necessary values for module composition
- Include descriptions for all outputs
- Mark sensitive outputs appropriately
- Follow consistent naming conventions

### Documentation
- README.md in each module directory
- Examples directory with usage patterns
- Variable descriptions and constraints
- Output descriptions and usage guidance

## Usage Examples

### Network Hub-Spoke Module
```hcl
module "network" {
  source = "./modules/network-hub-spoke"

  resource_group_name = var.resource_group_name
  location           = var.location
  environment        = var.environment

  hub_address_prefix   = "10.0.0.0/24"
  spoke_address_prefix = "10.1.0.0/16"

  tags = local.standard_tags
}
```

### FortiWeb HA Module
```hcl
module "fortiweb_ha" {
  source = "./modules/fortiweb-ha"

  resource_group_name = var.resource_group_name
  location           = var.location

  subnet_id          = module.network.hub_external_subnet_id
  high_availability  = var.production_environment
  instance_size      = var.production_environment ? "Standard_F4s_v2" : "Standard_F2s_v2"

  tags = local.standard_tags
}
```

## Benefits of Modular Architecture

### Reusability
- Modules can be reused across environments (dev, staging, prod)
- Standard patterns reduce configuration duplication
- Consistent implementation of best practices

### Testing
- Individual modules can be tested in isolation
- Terratest integration for automated validation
- Faster feedback cycles during development

### Maintainability
- Changes isolated to specific modules
- Version control for module evolution
- Clear dependency management

### Composition
- Complex infrastructure built from simple, well-tested components
- Flexible configuration through module parameters
- Easy to add new applications using standard patterns

## Migration Strategy

The existing monolithic configuration will be gradually refactored into modules:

1. **Phase 1**: Extract network configuration into hub-spoke module
2. **Phase 2**: Create FortiWeb HA module with enhanced availability
3. **Phase 3**: Modularize AKS cluster and application patterns
4. **Phase 4**: Add monitoring and certificate management modules
5. **Phase 5**: Update main configuration to use modules

## Testing Strategy

Each module includes:
- Terraform validation tests
- Terratest integration tests
- Example configurations
- Documentation validation

Run tests with:
```bash
cd modules/<module-name>
terraform init -backend=false
terraform validate
terraform fmt -check
go test -v ./test/
```
