plugin "azurerm" {
  enabled = true
  version = "0.29.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# Core Terraform rules (defaults are generally enabled; explicitly list a few common ones)
rule "terraform_deprecated_interpolation" { enabled = true }
rule "terraform_deprecated_index" { enabled = true }
rule "terraform_unused_declarations" { enabled = true }
rule "terraform_naming_convention" { enabled = true }
rule "terraform_comment_syntax" { enabled = true }
