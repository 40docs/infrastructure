# Ubuntu authd Configuration for Entra ID Authentication
#
# This file provides configuration examples for Ubuntu authd to integrate
# with the Azure Entra ID application created by the Terraform plan.
#
# Prerequisites:
# 1. Ubuntu 24.04 LTS or later with authd package installed
# 2. Entra ID application created using the provided Terraform or Azure CLI
# 3. Network connectivity to Azure endpoints

#===============================================================================
# authd Configuration File: /etc/authd/brokers.d/entra-id.conf
#===============================================================================

[broker "entra-id"]
# Brand name displayed to users
brand = "Microsoft"

# Azure Entra ID issuer URL (replace TENANT-ID with your actual tenant ID)
issuer = "https://login.microsoftonline.com/TENANT-ID/v2.0"

# OAuth2 Client Configuration
client_id = "YOUR-CLIENT-ID"
client_secret = "YOUR-CLIENT-SECRET"

# OAuth2 Scopes (what permissions to request)
scopes = "openid profile email User.Read"

# Token validation settings
token_timeout = "3600"  # 1 hour
refresh_token_timeout = "86400"  # 24 hours

# User mapping configuration
[broker "entra-id".user_mapping]
# Map Entra ID user attributes to local user attributes
username_attribute = "preferred_username"
name_attribute = "name"
email_attribute = "email"
groups_attribute = "groups"

# Home directory configuration
home_base_dir = "/home"
default_shell = "/bin/bash"
default_uid_min = 1000
default_gid_min = 1000

#===============================================================================
# systemd Service Configuration: /etc/systemd/system/authd.service.d/override.conf
#===============================================================================

[Service]
# Environment variables for authd
Environment="AUTHD_LOG_LEVEL=info"
Environment="AUTHD_BROKERS_CONFIG_DIR=/etc/authd/brokers.d"

# Network dependencies
After=network-online.target
Wants=network-online.target

#===============================================================================
# PAM Configuration: /etc/pam.d/common-auth
#===============================================================================

# Add this line to enable authd authentication
# auth    sufficient  pam_authd.so

#===============================================================================
# NSS Configuration: /etc/nsswitch.conf
#===============================================================================

# Modify the passwd and group lines to include authd
# passwd:         files authd systemd
# group:          files authd systemd

#===============================================================================
# Ubuntu authd Installation Commands
#===============================================================================

# Install authd (Ubuntu 24.04+)
sudo apt update
sudo apt install authselect-compat authd

# Enable and start authd service
sudo systemctl enable authd
sudo systemctl start authd

# Configure authentication
sudo authselect select compat-authd --force

#===============================================================================
# Testing Authentication
#===============================================================================

# Test the Entra ID broker configuration
sudo authd-cli broker test entra-id

# Test user login
# (Use the browser-based flow that will open)
authd-cli login --broker entra-id

# Check current authentication status
authd-cli status

#===============================================================================
# Security Considerations
#===============================================================================

# 1. Client Secret Security
# Store the client secret securely:
sudo mkdir -p /etc/authd/secrets
echo "YOUR-CLIENT-SECRET" | sudo tee /etc/authd/secrets/entra-id-secret > /dev/null
sudo chmod 600 /etc/authd/secrets/entra-id-secret
sudo chown root:root /etc/authd/secrets/entra-id-secret

# Then reference it in the broker config:
# client_secret_file = "/etc/authd/secrets/entra-id-secret"

# 2. Certificate-based Authentication (Recommended)
# Instead of client secrets, use certificate authentication:
# cert_path = "/etc/authd/certs/entra-id.pem"
# key_path = "/etc/authd/certs/entra-id.key"

# 3. Firewall Configuration
# Ensure outbound HTTPS access to:
# - login.microsoftonline.com
# - graph.microsoft.com

#===============================================================================
# Troubleshooting
#===============================================================================

# Check authd logs
sudo journalctl -u authd -f

# Increase log verbosity
sudo systemctl edit authd
# Add: Environment="AUTHD_LOG_LEVEL=debug"

# Test connectivity to Azure endpoints
curl -v "https://login.microsoftonline.com/TENANT-ID/v2.0/.well-known/openid_configuration"

# Verify broker configuration
sudo authd-cli broker list
sudo authd-cli broker info entra-id

#===============================================================================
# Advanced Configuration Options
#===============================================================================

[broker "entra-id".advanced]
# Cache settings
cache_timeout = "300"  # 5 minutes
max_cached_users = "1000"

# Network settings
http_timeout = "30"
max_redirects = "5"

# Conditional Access compliance
device_compliance_required = true
mfa_required = true

# Group synchronization
sync_groups = true
group_prefix = "entra-"
group_filter = "DisplayName -like '*CloudShell*'"

#===============================================================================
# Integration with Ubuntu Pro and Landscape
#===============================================================================

# If using Ubuntu Pro with Landscape management:
[broker "entra-id".ubuntu_pro]
enable_compliance_reporting = true
landscape_integration = true
security_updates_required = true
