# Terratest Makefile for 40docs Infrastructure

.PHONY: help test test-basic test-fixture test-validate test-plan clean deps

# Default target
help:
	@echo "Available targets:"
	@echo "  deps          - Install Go dependencies"
	@echo "  test          - Run all tests"
	@echo "  test-basic    - Run basic infrastructure tests (requires Azure auth)"
	@echo "  test-fixture  - Run fixture tests (requires Azure auth)"  
	@echo "  test-validate - Run validation tests (no Azure auth required)"
	@echo "  test-plan     - Run plan tests (no Azure auth required)"
	@echo "  clean         - Clean up test artifacts"
	@echo ""
	@echo "Prerequisites:"
	@echo "  - Go 1.21+ installed"
	@echo "  - Azure CLI installed and authenticated (for integration tests)"
	@echo "  - Terraform installed"

# Install Go dependencies
deps:
	@echo "Installing Go dependencies..."
	go mod tidy
	go mod download

# Run all tests
test: deps
	@echo "Running all Terratest tests..."
	go test -v -timeout 30m

# Run basic infrastructure tests (full integration)
test-basic: deps
	@echo "Running basic infrastructure tests..."
	@echo "Warning: This will create real Azure resources!"
	go test -v -timeout 45m -run TestBasicInfrastructure

# Run fixture tests (simplified integration)
test-fixture: deps
	@echo "Running fixture tests..."
	@echo "Warning: This will create real Azure resources!"
	go test -v -timeout 30m -run TestBasicFixture

# Run validation tests (no Azure resources created)
test-validate: deps
	@echo "Running validation tests..."
	go test -v -timeout 10m -run TestTerraformValidation

# Run plan tests (no Azure resources created)
test-plan: deps
	@echo "Running plan tests..."
	go test -v -timeout 15m -run TestTerraformPlan

# Clean up test artifacts
clean:
	@echo "Cleaning up test artifacts..."
	rm -rf .terraform/
	rm -rf fixtures/basic/.terraform/
	rm -f terraform.tfstate*
	rm -f fixtures/basic/terraform.tfstate*
	rm -f .terraform.lock.hcl
	rm -f fixtures/basic/.terraform.lock.hcl
	go clean -testcache

# Development targets
dev-validate:
	@echo "Running quick validation (development)..."
	cd .. && terraform init -backend=false
	cd .. && terraform validate
	cd .. && terraform fmt -check

dev-plan:
	@echo "Running development plan check..."
	@echo "Note: This requires proper Azure authentication"
	cd .. && terraform init -backend=false
	cd .. && terraform plan -var-file="test/test.tfvars"

# Continuous Integration targets
ci-validate: 
	@echo "CI: Running validation tests..."
	go test -v -timeout 5m -run TestTerraformValidation

ci-plan:
	@echo "CI: Running plan tests..."
	go test -v -timeout 10m -run TestTerraformPlan