# GitHub Actions Runner Registration Fix

## Problem Description

The CloudShell VM was experiencing GitHub Actions runner registration failures due to token expiration. The issue occurred because:

1. Terraform's `data.github_actions_organization_registration_token.org.token` generates a registration token that expires after 1 hour
2. The CloudShell VM's cloud-init process takes longer than 1 hour to complete
3. By the time the runner installation script executed, the registration token had already expired

## Solution Overview

The fix implements a runtime token generation approach that:

1. **Passes GitHub PAT token instead of registration token**: Uses the persistent `github_token` variable instead of the expiring registration token
2. **Generates fresh tokens at runtime**: Uses the GitHub API to create registration tokens when they're actually needed
3. **Implements comprehensive error handling**: Includes retry logic, validation, and secure logging
4. **Maintains security**: Prevents token exposure in logs through secure logging functions

## Files Modified

### 1. `/home/rmordasiewicz@fortinet-us.com/40docs/infrastructure/cloudshell.tf`

**Changes:**
- **Line 261**: Changed from `var_reg_token = data.github_actions_organization_registration_token.org.token` to `var_github_token = var.github_token`
- **Line 321-322**: Removed the `data "github_actions_organization_registration_token" "org"` data source
- **Added documentation**: Comments explaining the runtime token generation approach

### 2. `/home/rmordasiewicz@fortinet-us.com/40docs/infrastructure/cloud-init/CLOUDSHELL.conf`

**Major changes to the GitHub runner installation script:**

#### Security Enhancements
- **Secure Logging Function**: Added `secure_log()` function that redacts tokens from log output
- **Token Validation**: Added validation to ensure GitHub token is present and not null
- **Permission Checking**: Validates token can access the organization before proceeding

#### Runtime Token Generation
- **New Function**: `generate_registration_token()` that:
  - Uses GitHub API to generate fresh registration tokens
  - Implements exponential backoff retry logic (5 attempts)
  - Includes comprehensive error handling
  - Validates token extraction from API response

#### Enhanced Error Handling
- **Retry Logic**: Runner configuration now includes 3 retry attempts
- **Validation Checks**: Verifies registration token validity before use
- **Exit on Failure**: Scripts exit with proper error codes on failure
- **Comprehensive Logging**: All operations logged with timestamps and status

#### API Integration
- **GitHub API Calls**: Uses `curl` with proper headers for GitHub API v3
- **JSON Parsing**: Uses `jq` to extract tokens from API responses
- **Rate Limiting**: Implements delays between retry attempts

## Technical Implementation Details

### Token Generation Process

1. **Validation Phase**:
   ```bash
   validate_github_token()
   # - Checks organization access
   # - Validates token scopes
   # - Logs validation results
   ```

2. **Generation Phase**:
   ```bash
   generate_registration_token()
   # - Calls GitHub API: POST /orgs/{org}/actions/runners/registration-token
   # - Extracts token from JSON response
   # - Implements retry with exponential backoff
   # - Returns success/failure status
   ```

3. **Configuration Phase**:
   ```bash
   # - Validates generated token
   # - Configures runner with retry logic
   # - Installs and starts service
   # - Logs all operations securely
   ```

### Security Measures

1. **Token Redaction**: `secure_log()` function removes tokens from log output
2. **Input Validation**: Checks for null/empty tokens before use
3. **Minimal Exposure**: Tokens only used in API calls, not stored permanently
4. **Error Isolation**: API failures don't expose sensitive information

### Error Recovery

1. **Multiple Retry Attempts**: 5 attempts for token generation, 3 for configuration
2. **Exponential Backoff**: Wait times increase with each retry (10s, 20s, 40s, etc.)
3. **Graceful Degradation**: Clear error messages for troubleshooting
4. **Exit Codes**: Proper exit codes for different failure scenarios

## Prerequisites

### Required Variables
- `var.github_token`: Personal Access Token (PAT) with appropriate permissions
- `var.github_org`: GitHub organization name
- `var.runner_group`: Runner group name
- `var.runner_labels`: Comma-separated runner labels

### Required Permissions
The GitHub PAT token must have:
- `admin:org` scope (required for managing self-hosted runners)
- Access to the target organization
- Permission to create registration tokens

### Required Tools
The cloud-init environment includes:
- `curl`: For GitHub API calls
- `jq`: For JSON parsing
- Standard Linux utilities: `bash`, `sleep`, `date`

## Testing and Validation

### Pre-deployment Testing
1. **Token Validation**: Verify GitHub token has correct permissions
2. **API Accessibility**: Test GitHub API connectivity
3. **Organization Access**: Confirm token can access target organization

### Post-deployment Validation
1. **Runner Registration**: Check GitHub organization for new runner
2. **Service Status**: Verify runner service is running
3. **Log Analysis**: Review `/var/log/cloud-init-output.log` for errors
4. **Connectivity Test**: Confirm runner can accept jobs

### Troubleshooting Commands
```bash
# Check runner service status
systemctl status actions.runner.*.service

# View runner logs
journalctl -u actions.runner.*.service -f

# Check cloud-init logs
tail -f /var/log/cloud-init-output.log

# Verify runner in GitHub
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/orgs/$ORG/actions/runners
```

## Benefits

1. **Eliminates Token Expiration**: Tokens generated when needed, not hours in advance
2. **Improved Reliability**: Comprehensive retry and error handling
3. **Enhanced Security**: Token redaction and secure logging
4. **Better Monitoring**: Detailed logging for troubleshooting
5. **Maintainable Code**: Clear separation of concerns and documentation

## Migration Notes

### Breaking Changes
- **Variable Change**: `var_reg_token` replaced with `var_github_token`
- **Token Requirements**: Now requires PAT token instead of auto-generated registration token

### Deployment Considerations
1. **GitHub Secrets**: Ensure `github_token` is properly configured in GitHub secrets
2. **Token Rotation**: PAT tokens should be rotated according to security policies
3. **Permissions Review**: Verify token has minimum required permissions
4. **Backup Plan**: Keep previous version available for rollback if needed

## Future Improvements

1. **Token Caching**: Implement short-term caching to reduce API calls
2. **Health Checks**: Add periodic health checks for runner status
3. **Metrics Collection**: Add metrics for monitoring token generation success rates
4. **Integration Testing**: Automated tests for token generation and runner registration
5. **Documentation**: Additional runbooks for operational procedures

## Compatibility

- **Terraform Version**: Compatible with existing Terraform configuration
- **Azure Cloud**: No changes to Azure resource configuration
- **GitHub API**: Uses stable GitHub API v3 endpoints
- **Operating System**: Compatible with Ubuntu 24.04 (Noble)
- **Dependencies**: All required tools available in standard Ubuntu repositories

This fix provides a robust, secure, and maintainable solution for GitHub Actions runner registration in long-running cloud-init environments.
