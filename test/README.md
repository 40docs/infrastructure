# Infrastructure Testing Framework

Comprehensive testing strategy for 40docs infrastructure using Terratest, validation scripts, and automated checks.

## Testing Pyramid

```
                    E2E Tests
                   /         \
              Integration Tests
             /                 \
        Unit Tests        Validation Tests
       /        \         /              \
  Terraform   Security  Format      Lint
  Validate    Checks    Checks      Checks
```

## Test Categories

### 1. Static Analysis Tests
- **Terraform Validation**: Syntax and configuration validation
- **Security Scanning**: tfsec, Checkov, Trivy security analysis  
- **Code Quality**: terraform fmt, tflint validation
- **Documentation**: README and comment validation

### 2. Unit Tests (Terratest Go Tests)
- **Resource Creation**: Verify resources are created correctly
- **Configuration Values**: Validate variable interpolation and defaults
- **Output Verification**: Check output values and types
- **Dependency Testing**: Validate resource dependencies

### 3. Integration Tests
- **Network Connectivity**: Test hub-spoke network connectivity
- **Load Balancer Health**: Verify FortiWeb HA failover
- **AKS Cluster**: Validate cluster creation and node pools
- **Application Deployment**: Test Flux GitOps workflows

### 4. End-to-End Tests
- **Full Platform Deployment**: Complete infrastructure provisioning
- **Application Accessibility**: HTTP/HTTPS endpoint validation
- **Security Controls**: WAF protection and traffic inspection
- **Monitoring**: Alert generation and dashboard functionality

## Directory Structure

```
test/
├── unit/                    # Terraform unit tests
│   ├── network_test.go     # Network infrastructure tests
│   ├── fortiweb_test.go    # FortiWeb NVA tests
│   ├── aks_test.go         # AKS cluster tests
│   └── monitoring_test.go  # Monitoring configuration tests
├── integration/            # Integration test suites
│   ├── connectivity_test.go
│   ├── security_test.go
│   └── performance_test.go
├── e2e/                    # End-to-end test scenarios
│   ├── platform_test.go
│   └── application_test.go
├── fixtures/               # Test data and configurations
│   ├── terraform.tfvars.example
│   └── test-data.json
├── scripts/                # Test automation scripts
│   ├── run-tests.sh
│   ├── security-scan.sh
│   └── validate.sh
└── go.mod                  # Go module definition
```

## Test Execution

### Local Development Testing
```bash
# Quick validation (no Azure resources)
./scripts/validate.sh

# Security scanning
./scripts/security-scan.sh

# Unit tests (creates temporary Azure resources)
cd test/unit
go test -v -timeout 30m

# Integration tests (requires existing infrastructure)
cd test/integration  
go test -v -timeout 60m
```

### CI/CD Pipeline Testing
Tests run automatically in GitHub Actions:

1. **PR Validation**: Static analysis and unit tests
2. **Merge to Main**: Integration tests on staging environment
3. **Release**: Full E2E tests on production environment

### Manual Testing Commands
```bash
# Terraform validation
terraform init -backend=false
terraform validate
terraform fmt -check

# Security scanning
tfsec .
checkov -d .
trivy config .

# Run specific test suite
go test -v ./test/unit/network_test.go -timeout 20m
go test -v ./test/integration/ -timeout 45m
```

## Test Environment Requirements

### Prerequisites
- Go 1.19 or later
- Terraform 1.6 or later
- Azure CLI authenticated
- Required environment variables set

### Environment Variables
```bash
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
export AZURE_TENANT_ID="your-tenant-id"
export AZURE_CLIENT_ID="your-client-id"
export AZURE_CLIENT_SECRET="your-client-secret"
export TF_VAR_owner_email="test@example.com"
export TF_VAR_dns_zone="test.example.com"
```

### Test Resource Cleanup
Terratest automatically cleans up resources after tests complete. For failed tests:

```bash
# Manual cleanup
az group delete --name terratest-* --yes --no-wait

# Cleanup script
./scripts/cleanup-test-resources.sh
```

## Test Data Management

### Test Fixtures
- **terraform.tfvars.example**: Example variable configurations
- **test-data.json**: JSON test data for API testing
- **mock-responses/**: Mock API responses for unit tests

### Resource Naming
Test resources use consistent naming:
- **Pattern**: `terratest-{testname}-{random}`
- **Example**: `terratest-network-h7k2m`
- **Cleanup**: Resources automatically deleted by tag

## Test Metrics and Reporting

### Test Execution Metrics
- Test execution time per suite
- Resource creation/destruction time
- Success/failure rates by environment
- Coverage metrics for infrastructure components

### Test Reporting
- **JUnit XML**: For CI/CD integration
- **HTML Reports**: Detailed test results with logs
- **Slack Notifications**: Test status updates
- **Azure DevOps Integration**: Work item linking

## Best Practices

### Test Design
1. **Independent Tests**: Each test should be isolated and idempotent
2. **Resource Cleanup**: Always clean up Azure resources after testing
3. **Parallel Execution**: Design tests to run in parallel when possible
4. **Deterministic**: Tests should produce consistent results

### Test Data
1. **No Hardcoded Values**: Use variables and random generation
2. **Environment Separation**: Separate test data by environment
3. **Sensitive Data**: Never commit secrets or credentials
4. **Realistic Data**: Use production-like data for meaningful tests

### Performance
1. **Test Duration**: Unit tests <5min, Integration tests <30min, E2E <60min  
2. **Resource Limits**: Limit concurrent Azure resource creation
3. **Caching**: Cache Terraform providers and modules
4. **Cleanup**: Aggressive cleanup to avoid cost accumulation

## Troubleshooting

### Common Issues
- **Timeout Errors**: Increase test timeout values
- **Resource Conflicts**: Ensure unique resource naming
- **Network Issues**: Verify Azure connectivity and permissions
- **Cleanup Failures**: Manual resource cleanup may be required

### Debug Mode
```bash
# Enable debug logging
export TF_LOG=DEBUG
export TERRATEST_LOG_LEVEL=DEBUG

# Run single test with verbose output
go test -v -run TestNetworkModule -timeout 30m
```