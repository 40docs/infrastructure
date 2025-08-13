plugin "azurerm" {
  enabled = true
  version = "0.29.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# Core Terraform rules
rule "terraform_deprecated_interpolation" { enabled = true }
rule "terraform_deprecated_index" { enabled = true }
rule "terraform_comment_syntax" { enabled = true }

# Temporarily disable rules that conflict with established naming and stubs
# TODO: Re-enable once resource labels are migrated and variables are wired
rule "terraform_naming_convention" { enabled = false }
rule "terraform_unused_declarations" { enabled = false }
