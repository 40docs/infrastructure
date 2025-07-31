#===============================================================================
# TLS Certificate and Key Management
#
# This file manages TLS certificates and private keys for secure communication.
# Used for SSL/TLS termination in web applications and services.
#
# Resources:
# - Private key generation using RSA algorithm
# - Self-signed certificate for development and testing
#===============================================================================

# Generate private key for TLS certificate
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Generate self-signed certificate for development use
resource "tls_self_signed_cert" "self_signed_cert" {
  private_key_pem = tls_private_key.private_key.private_key_pem
  dns_names       = ["localhost.localdomain"]

  subject {
    common_name = "localhost.localdomain"
  }

  validity_period_hours = 87600 # 10 years
  early_renewal_hours   = 720   # 30 days

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}
