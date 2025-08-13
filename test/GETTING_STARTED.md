# Getting Started with Terratest

This guide helps you get started with the Terratest implementation for the 40docs infrastructure.

## Prerequisites

### Required Software
- **Go 1.21+**: [Download Go](https://golang.org/dl/)
- **Terraform 1.6+**: [Download Terraform](https://terraform.io/downloads)
- **Azure CLI**: [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Make**: Usually pre-installed on Linux/macOS

### Verify Installation
```bash
go version       # Should show 1.21+
terraform version # Should show 1.6+
az version       # Should show Azure CLI
make --version   # Should show GNU Make
```

## Quick Start (No Azure Required)

Start with tests that don't require Azure authentication:

### 1. Install Dependencies
```bash
cd test/
make deps
```

### 2. Run Validation Tests
```bash
# Test Terraform syntax and configuration
make test-validate
```

### 3. Run Plan Tests
```bash
# Test Terraform planning (no resources created)
make test-plan
```

These tests validate your Terraform code without creating real resources or requiring Azure authentication.

## Azure Integration Tests

For tests that create real Azure resources, you need Azure authentication.

### 1. Azure Authentication Setup

#### Option A: Interactive Login (Recommended for Development)
```bash
az login
az account set --subscription "your-subscription-name-or-id"
```

#### Option B: Service Principal (CI/CD)
```bash
az login --service-principal \
  -u $AZURE_CLIENT_ID \
  -p $AZURE_CLIENT_SECRET \
  --tenant $AZURE_TENANT_ID

az account set --subscription $AZURE_SUBSCRIPTION_ID
```

### 2. Verify Authentication
```bash
az account show
```

### 3. Run Fixture Tests
```bash
# Creates simplified Azure resources (VNets, subnets)
# Cost: ~$5-10 for 20 minutes
make test-fixture
```

### 4. Run Full Integration Tests
```bash
# Tests against full infrastructure (costs more)
# Cost: ~$20-50 for 45 minutes
make test-basic
```

## Test Structure

### Test Files Overview

| File | Purpose | Azure Auth | Resources Created | Duration |
|------|---------|------------|-------------------|----------|
| `basic_infrastructure_test.go` | Full infrastructure testing | ✅ Required | Many (expensive) | 30-45 min |
| `fixture_basic_test.go` | Simplified networking tests | ✅ Required | Few (cheap) | 15-20 min |
| Validation/Plan tests | Syntax and configuration | ❌ Not required | None | 1-5 min |

### Test Fixture vs Full Infrastructure

**Test Fixture** (`fixtures/basic/`):
- Simplified Terraform code
- Only creates VNets, subnets, and peering
- Faster execution and lower cost
- Good for basic validation

**Full Infrastructure** (parent directory):
- Complete infrastructure codebase
- Creates FortiWeb NVA, AKS cluster, applications
- Slower execution and higher cost
- Comprehensive testing

## Common Workflows

### Development Workflow
```bash
# 1. Make changes to Terraform code
vim ../variables.tf

# 2. Quick validation (fast, no cost)
make test-validate

# 3. Test planning (medium speed, no cost)
make test-plan

# 4. If changes affect networking, test with fixture (creates resources)
make test-fixture

# 5. For major changes, run full tests (expensive)
make test-basic
```

### CI/CD Workflow
```bash
# In CI pipeline
make ci-validate  # Fast validation
make ci-plan      # Plan validation

# In integration environment (if needed)
make test-fixture # Basic integration testing
```

### Debugging Workflow
```bash
# Run single test with verbose output
go test -v -run TestTerraformValidation -timeout 10m

# Run with debug logging
export TF_LOG=DEBUG
go test -v -run TestBasicFixture -timeout 30m

# Clean up after failed tests
make clean
```

## Cost Management

### Estimated Costs

| Test Type | Duration | Azure Cost | When to Use |
|-----------|----------|------------|-------------|
| Validation | 1 min | $0 | Always |
| Plan | 3-5 min | $0 | Before commits |
| Fixture | 15-20 min | $5-10 | Weekly/before PR |
| Full Integration | 30-45 min | $20-50 | Before releases |

### Cost Optimization Tips

1. **Use Fixture Tests First**: Test networking changes with cheaper fixture tests
2. **Automatic Cleanup**: Terratest automatically destroys resources after tests
3. **Monitor Costs**: Check Azure cost management for unexpected charges
4. **Parallel Limits**: Don't run multiple expensive tests simultaneously

## Troubleshooting

### Common Issues

#### Go Dependencies Error
```bash
# Fix: Update Go modules
go mod tidy
go clean -modcache
make deps
```

#### Azure Authentication Error
```bash
# Fix: Re-authenticate
az login
az account show  # Verify correct subscription
```

#### Terraform Backend Error
```bash
# Fix: Use local backend for tests
# This is already configured in the test files
```

#### Resource Cleanup Failed
```bash
# Manual cleanup
az group list --query "[?starts_with(name,'terratest')].name" -o tsv | \
  xargs -I {} az group delete --name {} --yes --no-wait

# Or use cleanup script
make clean
```

#### Test Timeout
```bash
# Increase timeout in go test command
go test -v -timeout 60m -run TestBasicFixture
```

### Debug Mode

```bash
# Enable detailed logging
export TF_LOG=DEBUG
export TERRATEST_LOG_LEVEL=DEBUG

# Run single test with maximum verbosity
go test -v -run TestBasicFixture -timeout 30m
```

### Getting Help

1. **Check Test Logs**: Look for specific error messages in test output
2. **Verify Azure Resources**: Check Azure portal for resource status
3. **Review Terraform Plans**: Use `terraform plan` manually to debug issues
4. **Check Prerequisites**: Ensure all required software is installed

## Next Steps

Once comfortable with basic testing:

1. **Add Custom Tests**: Create tests for specific infrastructure components
2. **Integrate with CI/CD**: Add tests to GitHub Actions workflow
3. **Expand Test Coverage**: Test additional scenarios and edge cases
4. **Performance Testing**: Add tests for infrastructure performance characteristics

## Example Test Run

```bash
# Complete workflow example
cd test/

# Install dependencies
make deps
✅ Installing Go dependencies...

# Quick validation
make test-validate
✅ Running validation tests...
✅ PASS: TestTerraformValidation (45s)

# Plan testing
make test-plan
✅ Running plan tests...
✅ PASS: TestTerraformPlan (3m21s)

# Integration testing (creates real resources)
make test-fixture
✅ Running fixture tests...
✅ Creating resource group: terratest-basic-h7k2m
✅ Creating VNets and subnets...
✅ Testing connectivity...
✅ Cleaning up resources...
✅ PASS: TestBasicFixture (18m32s)
```

You're now ready to use Terratest for infrastructure validation and testing!
