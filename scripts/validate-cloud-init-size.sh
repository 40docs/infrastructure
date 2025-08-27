#!/bin/bash
set -euo pipefail

# Cloud-init Template Size Validation Script
#
# This script validates that cloud-init templates stay within Azure's custom data size limits
# to prevent deployment failures. It interpolates templates with realistic sample values
# and calculates the actual Base64-encoded size that would be sent to Azure.
#
# Recent improvements:
# - Added support for all template variables including Azure ARM and AKS variables
# - Enhanced handling of Terraform's indent() function for SSH keys
# - More accurate size calculations with realistic sample data
# - Better error reporting with specific optimization suggestions
#
# Azure VM Custom Data Limits
AZURE_LIMIT=87380
SAFETY_THRESHOLD=90  # 90% of limit = 78,642 characters

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[VALIDATE]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Generate realistic sample kubeconfig (Base64 encoded)
generate_sample_kubeconfig() {
    # Create a realistic kubeconfig with large certificate data
    local kubeconfig_content
    kubeconfig_content=$(cat <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $(head -c 4000 < /dev/zero | tr '\0' 'A' | base64 -w 0)
    server: https://test-aks-cluster-12345678.hcp.westus2.azmk8s.io:443
  name: test-aks-cluster
contexts:
- context:
    cluster: test-aks-cluster
    user: clusterUser_test-resource-group_test-aks-cluster
  name: test-aks-cluster
current-context: test-aks-cluster
kind: Config
preferences: {}
users:
- name: clusterUser_test-resource-group_test-aks-cluster
  user:
    client-certificate-data: $(head -c 4000 < /dev/zero | tr '\0' 'B' | base64 -w 0)
    client-key-data: $(head -c 4000 < /dev/zero | tr '\0' 'C' | base64 -w 0)
    token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjEyMzQ1Njc4OTAiLCJ0eXAiOiJKV1QifQ.$(head -c 2000 < /dev/zero | tr '\0' 'D')
EOF
)
    echo "$kubeconfig_content" | base64 -w 0
}

# Generate realistic SSH keys
generate_sample_rsa_key() {
    cat <<EOF
-----BEGIN PRIVATE KEY-----
$(head -c 3000 < /dev/zero | tr '\0' 'X' | fold -w 64)
-----END PRIVATE KEY-----
EOF
}

generate_sample_ecdsa_key() {
    cat <<EOF
-----BEGIN PRIVATE KEY-----
$(head -c 800 < /dev/zero | tr '\0' 'Y' | fold -w 64)
-----END PRIVATE KEY-----
EOF
}

generate_sample_ed25519_key() {
    cat <<EOF
-----BEGIN OPENSSH PRIVATE KEY-----
$(head -c 400 < /dev/zero | tr '\0' 'Z' | fold -w 64)
-----END OPENSSH PRIVATE KEY-----
EOF
}

# Function to interpolate template with realistic sample values
interpolate_template() {
    local template_file="$1"
    local temp_file
    temp_file=$(mktemp)

    log "Generating sample data for interpolation..."

    # Generate sample values
    local sample_kubeconfig
    sample_kubeconfig=$(generate_sample_kubeconfig)

    local sample_rsa_key
    sample_rsa_key=$(generate_sample_rsa_key)

    local sample_ecdsa_key
    sample_ecdsa_key=$(generate_sample_ecdsa_key)

    local sample_ed25519_key
    sample_ed25519_key=$(generate_sample_ed25519_key)

    # Perform substitutions using temporary files to handle multiline content
    cp "$template_file" "$temp_file"

    # Replace kubeconfig (largest variable)
    echo "$sample_kubeconfig" > "${temp_file}.kubeconfig"
    sed -i.bak "s|\${var_kubeconfig}|$(cat "${temp_file}.kubeconfig")|g" "$temp_file"

    # Handle Terraform indent() function for SSH keys
    # indent(4, var_ssh_host_rsa_private) -> 4-space indented RSA key
    echo "$sample_rsa_key" > "${temp_file}.rsa"
    echo "$sample_rsa_key" | sed 's/^/    /' > "${temp_file}.rsa_indented"
    sed -i.bak "s|\${indent(4, var_ssh_host_rsa_private)}|$(cat "${temp_file}.rsa_indented" | tr '\n' '\001' | sed 's/\001/\\n/g')|g" "$temp_file" 2>/dev/null || true
    sed -i.bak "s|\${var_ssh_host_rsa_private}|$(cat "${temp_file}.rsa")|g" "$temp_file" 2>/dev/null || true
    sed -i.bak "s|\${var_ssh_host_rsa_public}|ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC8test1234567890|g" "$temp_file"

    echo "$sample_rsa_key" | sed 's/^/    /' > "${temp_file}.rsa_pub_indented"
    sed -i.bak "s|\${indent(4, var_ssh_host_rsa_public)}|$(cat "${temp_file}.rsa_pub_indented" | tr '\n' '\001' | sed 's/\001/\\n/g')|g" "$temp_file" 2>/dev/null || true

    echo "$sample_ecdsa_key" > "${temp_file}.ecdsa"
    echo "$sample_ecdsa_key" | sed 's/^/    /' > "${temp_file}.ecdsa_indented"
    sed -i.bak "s|\${indent(4, var_ssh_host_ecdsa_private)}|$(cat "${temp_file}.ecdsa_indented" | tr '\n' '\001' | sed 's/\001/\\n/g')|g" "$temp_file" 2>/dev/null || true
    sed -i.bak "s|\${var_ssh_host_ecdsa_private}|$(cat "${temp_file}.ecdsa")|g" "$temp_file" 2>/dev/null || true
    sed -i.bak "s|\${var_ssh_host_ecdsa_public}|ecdsa-sha2-nistp521 AAAAEtest|g" "$temp_file"

    echo "ecdsa-sha2-nistp521 AAAAEtest" | sed 's/^/    /' > "${temp_file}.ecdsa_pub_indented"
    sed -i.bak "s|\${indent(4, var_ssh_host_ecdsa_public)}|$(cat "${temp_file}.ecdsa_pub_indented" | tr '\n' '\001' | sed 's/\001/\\n/g')|g" "$temp_file" 2>/dev/null || true

    echo "$sample_ed25519_key" > "${temp_file}.ed25519"
    echo "$sample_ed25519_key" | sed 's/^/    /' > "${temp_file}.ed25519_indented"
    sed -i.bak "s|\${indent(4, var_ssh_host_ed25519_private)}|$(cat "${temp_file}.ed25519_indented" | tr '\n' '\001' | sed 's/\001/\\n/g')|g" "$temp_file" 2>/dev/null || true
    sed -i.bak "s|\${var_ssh_host_ed25519_private}|$(cat "${temp_file}.ed25519")|g" "$temp_file" 2>/dev/null || true
    sed -i.bak "s|\${var_ssh_host_ed25519_public}|ssh-ed25519 AAAAtest|g" "$temp_file"

    echo "ssh-ed25519 AAAAtest" | sed 's/^/    /' > "${temp_file}.ed25519_pub_indented"
    sed -i.bak "s|\${indent(4, var_ssh_host_ed25519_public)}|$(cat "${temp_file}.ed25519_pub_indented" | tr '\n' '\001' | sed 's/\001/\\n/g')|g" "$temp_file" 2>/dev/null || true

    # Replace other variables with realistic values
    sed -i.bak "s|\${var_directory_tenant_id}|12345678-1234-1234-1234-123456789012|g" "$temp_file"
    sed -i.bak "s|\${var_directory_client_id}|87654321-4321-4321-4321-210987654321|g" "$temp_file"
    sed -i.bak "s|\${var_forticnapp_account}|testfortiaccount1234567890|g" "$temp_file"
    sed -i.bak "s|\${var_forticnapp_subaccount}|testfortisubaccount1234567890|g" "$temp_file"
    sed -i.bak "s|\${var_forticnapp_api_key}|test-forti-api-key-1234567890abcdefghijklmnop|g" "$temp_file"
    sed -i.bak "s|\${var_forticnapp_api_secret}|test-forti-api-secret-1234567890abcdefghijklmnop|g" "$temp_file"
    sed -i.bak "s|\${var_admin_username}|testusername|g" "$temp_file"
    sed -i.bak "s|\${var_brave_api_key}|test-brave-api-key-1234567890abcdefghijklmnop|g" "$temp_file"
    sed -i.bak "s|\${var_perplexity_api_key}|test-perplexity-api-key-1234567890abcdefghijklmnop|g" "$temp_file"
    sed -i.bak "s|\${var_anthropic_api_key}|test-anthropic-api-key-1234567890abcdefghijklmnop|g" "$temp_file"
    sed -i.bak "s|\${var_github_token}|test-github-token-ghp_1234567890abcdefghijklmnop|g" "$temp_file"
    sed -i.bak "s|\${var_github_org}|testorganization|g" "$temp_file"
    sed -i.bak "s|\${var_runner_group}|default|g" "$temp_file"
    sed -i.bak "s|\${var_runner_labels}|self-hosted,linux,x64,gpu|g" "$temp_file"
    sed -i.bak "s|\${var_has_gpu}|true|g" "$temp_file"

    # Add missing Azure and AKS variables
    sed -i.bak "s|\${var_arm_subscription_id}|12345678-9012-3456-7890-123456789012|g" "$temp_file"
    sed -i.bak "s|\${var_arm_client_id}|87654321-4321-4321-4321-210987654321|g" "$temp_file"
    sed -i.bak "s|\${var_arm_client_secret}|test-arm-client-secret-1234567890abcdefghijklmnopqrstuvwxyz|g" "$temp_file"
    sed -i.bak "s|\${var_arm_tenant_id}|11111111-2222-3333-4444-555555555555|g" "$temp_file"
    sed -i.bak "s|\${var_aks_resource_group}|test-resource-group-aks-cluster-eastus|g" "$temp_file"
    sed -i.bak "s|\${var_aks_cluster_name}|test-aks-cluster-eastus-001-production|g" "$temp_file"

    # Catch any remaining variables
    sed -i.bak "s|\${var_[a-zA-Z_]*}|sample-value-123456789012345|g" "$temp_file"

    # Return the interpolated content
    cat "$temp_file"

    # Cleanup
    rm -f "$temp_file" "${temp_file}.bak" "${temp_file}".* 2>/dev/null || true
}

# Validate cloud-init template size
validate_template() {
    local template_file="$1"
    local filename
    filename=$(basename "$template_file")

    log "Validating template: $filename"

    if [[ ! -f "$template_file" ]]; then
        error "Template file not found: $template_file"
        return 1
    fi

    # Get raw template size
    local raw_template_size
    raw_template_size=$(wc -c < "$template_file")
    log "Raw template size: $raw_template_size characters"

    # Interpolate template with sample values
    log "Interpolating template with realistic sample values..."
    local interpolated_content
    interpolated_content=$(interpolate_template "$template_file")

    if [[ -z "$interpolated_content" ]]; then
        error "Failed to interpolate template"
        return 1
    fi

    # Calculate sizes
    local raw_size
    raw_size=$(echo "$interpolated_content" | wc -c)

    local base64_size
    base64_size=$(echo "$interpolated_content" | base64 -w 0 | wc -c)

    local threshold_size
    threshold_size=$(( AZURE_LIMIT * SAFETY_THRESHOLD / 100 ))

    local usage_percentage
    usage_percentage=$(( base64_size * 100 / AZURE_LIMIT ))

    # Display results
    echo
    log "Size Analysis Results:"
    echo "  Raw interpolated size: $raw_size characters"
    echo "  Base64 encoded size:   $base64_size characters"
    echo "  Safety threshold (90%): $threshold_size characters"
    echo "  Azure limit:           $AZURE_LIMIT characters"
    echo "  Current usage:         $usage_percentage% of Azure limit"

    # Validate against threshold
    if [[ $base64_size -gt $threshold_size ]]; then
        local overage
        overage=$(( base64_size - threshold_size ))
        echo
        error "❌ VALIDATION FAILED: Template exceeds 90% of Azure limit"
        error "   Current size: $base64_size characters"
        error "   Safe threshold: $threshold_size characters"
        error "   Overage: $overage characters"
        error "   Usage: $usage_percentage% of limit"
        echo
        error "The template is too large and will likely cause Azure deployment failures."
        error "Consider:"
        error "  1. Moving large data (kubeconfig, SSH keys) to external storage"
        error "  2. Splitting configuration into multiple scripts"
        error "  3. Removing unnecessary packages or commands"
        error "  4. Using Azure VM Extensions instead of cloud-init"
        error "  5. Externalizing npm package installations to download scripts"
        error "  6. Reducing Ollama model list or using post-deployment downloads"
        error "  7. Simplifying SSH security hardening configurations"
        return 1
    elif [[ $base64_size -gt $(( AZURE_LIMIT * 80 / 100 )) ]]; then
        warn "⚠️  WARNING: Template is approaching size limits"
        warn "   Current: $usage_percentage% of Azure limit"
        warn "   Consider optimizing before adding more content"
        success "✅ Validation passed with warnings"
        return 0
    else
        success "✅ VALIDATION PASSED: Template size is within safe limits"
        success "   Using $usage_percentage% of Azure limit"
        success "   Remaining capacity: $(( threshold_size - base64_size )) characters"
        return 0
    fi
}

# Main execution
main() {
    if [[ $# -eq 0 ]]; then
        error "Usage: $0 <cloud-init-template-file> [additional-files...]"
        error "Example: $0 cloud-init/CLOUDSHELL.conf"
        exit 1
    fi

    log "Starting cloud-init template size validation"
    log "Azure custom data limit: $AZURE_LIMIT characters (Base64 encoded)"
    log "Safety threshold: $SAFETY_THRESHOLD% = $(( AZURE_LIMIT * SAFETY_THRESHOLD / 100 )) characters"
    echo

    local exit_code=0

    # Validate each template file
    for template in "$@"; do
        if ! validate_template "$template"; then
            exit_code=1
        fi
        echo
    done

    if [[ $exit_code -eq 0 ]]; then
        success "All template validations passed!"
    else
        error "One or more template validations failed!"
        error "Please optimize templates before committing."
    fi

    exit $exit_code
}

# Execute main function with all arguments
main "$@"
