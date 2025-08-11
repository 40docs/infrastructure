package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

// TestBasicInfrastructure tests the basic infrastructure deployment
// This test validates resource group, networking, and basic resource creation
// NOTE: This test creates real Azure resources and requires authentication
func TestBasicInfrastructure(t *testing.T) {
	t.Skip("Skipping full integration test - requires Azure authentication and creates expensive resources")
}

// TestTerraformValidation runs terraform validate to check syntax
func TestTerraformValidation(t *testing.T) {
	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		NoColor:      true,
	}

	// Initialize without backend
	terraform.RunTerraformCommand(t, terraformOptions, "init", "-backend=false")
	
	// Run terraform validate (no variables needed for syntax validation)
	terraform.RunTerraformCommand(t, terraformOptions, "validate")
}

// TestTerraformPlan runs terraform plan to check for errors
// NOTE: This test requires Azure backend configuration and is disabled for local testing
func TestTerraformPlan(t *testing.T) {
	t.Skip("Skipping plan test - requires Azure backend configuration and authentication")
}