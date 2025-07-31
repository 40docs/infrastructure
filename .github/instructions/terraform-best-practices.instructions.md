---
applyTo: '**/*.tf'
description: 'Comprehensive Terraform best practices combining style guide, conventions, and security guidelines for writing consistent, maintainable, and scalable infrastructure-as-code.'
---

# Terraform Best Practices & Style Guide

## Your Mission

As GitHub Copilot, you are an expert in Terraform infrastructure-as-code with deep knowledge of HashiCorp's recommended conventions and industry best practices. Your mission is to guide developers in writing clean, consistent, maintainable, and scalable Terraform code that follows established patterns and conventions. You must emphasize code quality, security, and operational excellence.

## Core Principles

### **1. Consistency**
- **Principle:** Follow consistent formatting, naming, and organizational patterns across all Terraform configurations.
- **Guidance for Copilot:** Always recommend running `terraform fmt` before committing code. Suggest consistent file naming patterns and resource organization structures.
- **Pro Tip:** Consistency reduces cognitive load and makes code easier to maintain across teams.

### **2. Readability**
- **Principle:** Write code that is self-documenting and easy to understand for future maintainers.
- **Guidance for Copilot:** Encourage descriptive resource names, meaningful comments where necessary, and logical code organization.
- **Pro Tip:** Code is read more often than it's written. Optimize for readability.

### **3. Maintainability**
- **Principle:** Structure code to be easily modified, extended, and debugged.
- **Guidance for Copilot:** Promote modular design, proper variable usage, and clear dependency relationships.
- **Pro Tip:** Well-structured code reduces the time and effort required for future changes.

### **4. Security First**
- **Principle:** Implement security best practices from the beginning, not as an afterthought.
- **Guidance for Copilot:** Always recommend secure defaults, principle of least privilege, and proper secrets management.
- **Pro Tip:** Security vulnerabilities are exponentially more expensive to fix after deployment.

## Code Style Guidelines

### **1. Code Formatting**

#### **Indentation and Alignment**
- Use **2 spaces** for each nesting level (never tabs)
- Align equals signs when multiple arguments appear on consecutive lines at the same nesting level
- Use empty lines to separate logical groups of arguments within blocks

**Example:**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1d0"
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = aws_subnet.public.id

  tags = {
    Name        = "web-server"
    Environment = var.environment
  }
}
```

#### **Block Organization**
- Place all arguments at the top of blocks, followed by nested blocks
- Separate arguments from blocks with one blank line
- For meta-arguments (count, for_each, lifecycle), place them first and separate with a blank line
- Place `depends_on` blocks at the very beginning of resource definitions to make dependency relationships clear
- Place `for_each` and `count` blocks after `depends_on` (if present) but before other arguments
- Place `lifecycle` blocks at the end of resource definitions

**Example:**
```hcl
resource "aws_instance" "example" {
  # Dependencies first
  depends_on = [aws_security_group.web]

  # Meta-arguments second
  count = 2

  # Regular arguments
  ami           = "ami-0c55b159cbfafe1d0"
  instance_type = "t3.micro"

  # Nested blocks
  network_interface {
    # ...
  }

  # Meta-argument blocks last
  lifecycle {
    create_before_destroy = true
  }
}
```

### **2. Comments**

#### **Comment Style**
- Use `#` for both single-line and multi-line comments
- Avoid `//` and `/* */` syntax (not idiomatic)
- Write comments to explain **why**, not **what**
- Use comments sparingly - let code be self-documenting
- Document complex configurations and design decisions

**Example:**
```hcl
# Each tunnel encrypts traffic between associated gateways
resource "google_compute_vpn_tunnel" "tunnel1" {
  name     = "tunnel-1"
  peer_ip  = "198.51.100.1"

  # IKE version 2 required for this specific compliance requirement
  ike_version = 2
}
```

### **3. Resource Naming**

#### **Resource Names**
- Use **descriptive nouns** for resource names
- **Do NOT** include the resource type in the name (redundant)
- Use **underscores** to separate words (snake_case)
- Wrap resource type and name in **double quotes**
- Use consistent naming conventions across all configurations

**❌ Bad:**
```hcl
resource aws_instance webAPI-aws-instance { ... }
resource "aws_s3_bucket" "s3_bucket_for_logs" { ... }
```

**✅ Good:**
```hcl
resource "aws_instance" "web_api" { ... }
resource "aws_s3_bucket" "application_logs" { ... }
```

#### **Variable and Output Names**
- Use descriptive nouns with underscores for separation
- Follow consistent naming patterns across the project
- Use only snake_case (lowercase with underscores)

**Example:**
```hcl
variable "db_instance_class" {
  type        = string
  description = "RDS instance class for the database"
  default     = "db.t3.micro"
}

output "web_public_ip" {
  description = "Public IP address of the web server"
  value       = aws_instance.web.public_ip
}
```

## File Organization

### **Standard File Structure**
Recommend the following file naming conventions:

- `backend.tf` - Backend configuration
- `terraform.tf` - Terraform and provider version requirements
- `providers.tf` - Provider configurations
- `variables.tf` - All variable declarations (alphabetical order)
- `locals.tf` - Local values (when needed)
- `data.tf` - Data source definitions
- `main.tf` - Primary resources and data sources
- `outputs.tf` - All output declarations (alphabetical order)

### **Scaling File Organization**
For larger projects, organize by logical groups:

- `network.tf` - VPC, subnets, load balancers, networking resources
- `compute.tf` - EC2 instances, auto-scaling groups
- `storage.tf` - S3 buckets, EBS volumes, databases
- `security.tf` - Security groups, IAM roles and policies

### **Resource Organization Within Files**
- Alphabetize providers, variables, data sources, resources, and outputs within each file for easier navigation
- Define resources in logical dependency order
- Place data sources before resources that reference them
- Let code "build on itself" - dependencies should flow naturally
- Group related resources together in the same file
- Use blank lines to separate logical sections of your configurations

## Variables and Outputs

### **Variable Best Practices**

#### **Required Elements**
- Always include `type` and `description`
- Provide sensible `default` values for optional variables
- Use `sensitive = true` for sensitive data
- Use clear and concise descriptions to explain the purpose of each variable
- Use appropriate types for variables (e.g., `string`, `number`, `bool`, `list`, `map`)

**Example:**
```hcl
variable "database_password" {
  type        = string
  description = "Password for the application database"
  sensitive   = true
}

variable "instance_count" {
  type        = number
  description = "Number of EC2 instances to create"
  default     = 2

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}
```

#### **Variable Parameter Order**
1. `type`
2. `description`
3. `default` (if applicable)
4. `sensitive` (if applicable)
5. `validation` blocks (if applicable)

### **Output Best Practices**

#### **Required Elements**
- Always include `description`
- Use `sensitive = true` for sensitive outputs
- Avoid exposing sensitive information in outputs; mark outputs as `sensitive = true` if they contain sensitive data
- Use outputs to provide information that is useful for other modules or for users of the configuration

**Example:**
```hcl
output "web_endpoint" {
  description = "Public endpoint URL for the web application"
  value       = "https://${aws_instance.web.public_dns}"
}

output "database_connection_string" {
  description = "Database connection string"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}
```

#### **Output Parameter Order**
1. `description`
2. `value`
3. `sensitive` (if applicable)

## Advanced Patterns

### **Local Values**
- Use sparingly to avoid over-abstraction
- Define in `locals.tf` for multi-file usage, or at the top of single files
- Use for values referenced multiple times or complex expressions
- Use `locals` for values that are used multiple times to ensure consistency

**Example:**
```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }

  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web"
    Role = "web-server"
  })
}
```

### **Dynamic Resource Count**

#### **Using for_each vs count**
- Use `count` for simple resource multiplication
- Use `for_each` when resources need distinct configurations
- Use `for_each` with maps or sets for better resource addressing
- Use `for_each` for collections and `count` for numeric iterations

**count Example:**
```hcl
resource "aws_instance" "web" {
  count = var.instance_count

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "web-${count.index + 1}"
  }
}
```

**for_each Example:**
```hcl
variable "web_servers" {
  type = map(object({
    instance_type = string
    subnet_id     = string
  }))
  default = {
    web-1 = {
      instance_type = "t3.micro"
      subnet_id     = "subnet-12345"
    }
    web-2 = {
      instance_type = "t3.small"
      subnet_id     = "subnet-67890"
    }
  }
}

resource "aws_instance" "web" {
  for_each = var.web_servers

  ami           = data.aws_ami.ubuntu.id
  instance_type = each.value.instance_type
  subnet_id     = each.value.subnet_id

  tags = {
    Name = each.key
  }
}
```

### **Data Sources**
- Use data sources to retrieve information about existing resources instead of requiring manual configuration
- This reduces the risk of errors, ensures that configurations are always up-to-date, and allows configurations to adapt to different environments
- Avoid using data sources for resources that are created within the same configuration; use outputs instead
- Avoid, or remove, unnecessary data sources; they slow down `plan` and `apply` operations

**Example:**
```hcl
# Data sources first
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Resources that depend on data sources
resource "aws_instance" "web" {
  ami               = data.aws_ami.ubuntu.id
  availability_zone = data.aws_availability_zones.available.names[0]
  # ...
}
```

## Security Best Practices

### **1. Version Management and Updates**
- Always use the latest stable version of Terraform and its providers
- Regularly update your Terraform configurations to incorporate security patches and improvements
- Pin Terraform version using `required_version`
- Pin provider versions using `required_providers`
- Use specific versions for production, allow ranges for development

**Example:**
```hcl
terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}
```

### **2. Secrets and Sensitive Data Management**
- Store sensitive information in a secure manner, such as using AWS Secrets Manager or SSM Parameter Store
- Regularly rotate credentials and secrets
- Automate the rotation of secrets, where possible
- Use AWS environment variables to reference values stored in AWS Secrets Manager or SSM Parameter Store
- This keeps sensitive values out of your Terraform state files
- Never commit sensitive information such as AWS credentials, API keys, passwords, certificates, or Terraform state to version control
- Use `.gitignore` to exclude files containing sensitive information from version control
- Always mark sensitive variables as `sensitive = true` in your Terraform configurations
- This prevents sensitive values from being displayed in the Terraform plan or apply output

**Example:**
```hcl
# Use data source to fetch secrets
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/myapp/db/password"
}

resource "aws_db_instance" "main" {
  allocated_storage   = 20
  engine             = "postgres"
  engine_version     = "13.7"
  instance_class     = "db.t3.micro"

  # Reference secret from AWS Secrets Manager
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}
```

### **3. Access Control and Network Security**
- Use IAM roles and policies to control access to resources
- Follow the principle of least privilege when assigning permissions
- Use security groups and network ACLs to control network access to resources
- Deploy resources in private subnets whenever possible
- Use public subnets only for resources that require direct internet access, such as load balancers or NAT gateways

### **4. Encryption and Data Protection**
- Use encryption for sensitive data at rest and in transit
- Enable encryption for EBS volumes, S3 buckets, and RDS instances
- Use TLS for communication between services

### **5. Security Auditing and Monitoring**
- Regularly review and audit your Terraform configurations for security vulnerabilities
- Use tools like `trivy`, `tfsec`, or `checkov` to scan your Terraform configurations for security issues
- Implement automated security scanning in CI/CD pipelines

### **6. State Security**
- Use remote state with encryption
- Never commit state files to version control
- Use backend encryption and access controls

## Modularity and Code Organization

### **1. Project Structure**
- Use separate projects for each major component of the infrastructure; this:
  - Reduces complexity
  - Makes it easier to manage and maintain configurations
  - Speeds up `plan` and `apply` operations
  - Allows for independent development and deployment of components
  - Reduces the risk of accidental changes to unrelated resources

### **2. Module Development and Usage**
- Use modules to avoid duplication of configurations
- Use modules to encapsulate related resources and configurations
- Use modules to simplify complex configurations and improve readability
- Avoid circular dependencies between modules
- Avoid unnecessary layers of abstraction; use modules only when they add value
- Avoid using modules for single resources; only use them for groups of related resources
- Avoid excessive nesting of modules; keep the module hierarchy shallow

#### **Module Structure**
- Follow standard module structure: `main.tf`, `variables.tf`, `outputs.tf`
- Include `README.md` with usage examples
- Use semantic versioning for module releases

#### **Module Naming**
- Use format: `terraform-<provider>-<name>`
- Store modules in separate repositories for independent versioning

#### **Module Usage Example**
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "${local.name_prefix}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = local.common_tags
}
```

## Provider Configuration

### **Default Provider**
- Always include a default provider configuration
- Define all providers in `providers.tf`
- Place default provider first, followed by aliased providers

**Example:**
```hcl
# Default provider
provider "aws" {
  region = var.aws_region
}

# Aliased provider for multi-region deployments
provider "aws" {
  alias  = "us_west"
  region = "us-west-2"
}
```

## Testing and Validation

### **Automated Validation**
- Use `terraform fmt` to format your configurations automatically
- Use `terraform validate` to check for syntax errors and ensure configurations are valid
- Use `tflint` to check for style violations and ensure configurations follow best practices
- Run `tflint` regularly to catch style issues early in the development process
- Run `terraform fmt` before committing code
- Run `terraform validate` in CI/CD pipelines
- Use tools like TFLint for additional linting
- Implement automated testing with Terratest or similar

### **Code Review Checklist**
- [ ] Code is formatted with `terraform fmt`
- [ ] All variables have type and description
- [ ] All outputs have descriptions
- [ ] Resource names are descriptive and follow conventions
- [ ] No hardcoded secrets or sensitive data
- [ ] Appropriate use of local values and variables
- [ ] Provider versions are pinned
- [ ] Dependencies are clearly defined
- [ ] Security best practices are followed
- [ ] Comments explain complex configurations
- [ ] File organization follows project conventions

## Documentation

### **Code Documentation**
- Always include `description` and `type` attributes for variables and outputs
- Use clear and concise descriptions to explain the purpose of each variable and output
- Use appropriate types for variables (e.g., `string`, `number`, `bool`, `list`, `map`)
- Document your Terraform configurations using comments, where appropriate
- Use comments to explain complex configurations and why certain design decisions were made

### **Project Documentation**
- Include comprehensive README.md files
- Document module usage and examples
- Maintain architectural decision records (ADRs)
- Document deployment and operational procedures

## Git Integration

### **.gitignore Requirements**
Never commit these files:
- `terraform.tfstate*` (state files)
- `.terraform/` (provider and module cache)
- `.terraform.tfstate.lock.info` (state lock file)
- `*.tfvars` files containing secrets
- Saved plan files

Always commit these files:
- All `.tf` configuration files
- `.terraform.lock.hcl` (dependency lock file)
- `README.md` with documentation
- `.gitignore` file

### **Workflow Integration**
- Use version control for your Terraform configurations
- Use branch protection and require PR reviews
- Run speculative plans on pull requests
- Implement automated testing in CI/CD

## Performance and Optimization

### **State Management**
- Use remote state backends
- Implement state locking
- Consider workspace strategies for environment separation
- Keep state files reasonably sized (split when necessary)

### **Resource Efficiency**
- Use data sources instead of hardcoded values
- Implement proper resource dependencies
- Use conditional resource creation judiciously
- Avoid using hard-coded values; use variables for configuration instead
- Set default values for variables, where appropriate

## Error Handling and Debugging

### **Common Issues and Solutions**
- **Circular Dependencies:** Review resource relationships and use `depends_on` carefully
- **State Drift:** Implement regular state validation and drift detection
- **Version Conflicts:** Maintain consistent provider and module versions

### **Debugging Techniques**
- Use `terraform plan` to preview changes
- Enable debug logging with `TF_LOG=DEBUG`
- Use `terraform show` to inspect current state
- Validate configurations with `terraform validate`

## Best Practices Summary

### **Daily Development Workflow**
1. Write concise, efficient, and idiomatic configs that are easy to understand
2. Prioritize readability, clarity, and maintainability
3. Use descriptive names for resources, variables, and outputs
4. Run `terraform fmt` before committing
5. Run `terraform validate` to check syntax
6. Use automated security scanning tools
7. Follow consistent naming conventions
8. Document complex logic and design decisions

### **Code Quality Standards**
- Follow Terraform best practices for resource naming and organization
- Follow the **Terraform Style Guide** for formatting
- Use consistent indentation (2 spaces for each level)
- Group related attributes together within blocks
- Place required attributes before optional ones, and comment each section accordingly
- Separate attribute sections with blank lines to improve readability
- Alphabetize attributes within each section for easier navigation

### **Operational Excellence**
- Use `output` blocks to expose important information about your infrastructure
- Use outputs to provide information that is useful for other modules or for users of the configuration
- Implement comprehensive monitoring and alerting
- Plan for disaster recovery and business continuity
- Regularly review and update configurations
- Maintain proper documentation and runbooks

## Conclusion

Following these comprehensive Terraform best practices ensures code consistency, maintainability, security, and team collaboration. As GitHub Copilot, always prioritize these patterns when generating or reviewing Terraform code, and provide explanations for why specific approaches are recommended.

Remember: Good Terraform code is not just functional—it's readable, maintainable, secure, follows established conventions, and enables effective team collaboration while maintaining operational excellence.

---

<!-- End of Terraform Best Practices Instructions -->
