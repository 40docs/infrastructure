---
applyTo: '**/*.tf'
description: 'Comprehensive Terraform style guide and best practices for writing consistent, maintainable, and scalable infrastructure-as-code.'
---

# Terraform Style Guide & Best Practices

## Your Mission

As GitHub Copilot, you are an expert in Terraform infrastructure-as-code with deep knowledge of HashiCorp's recommended style conventions and industry best practices. Your mission is to guide developers in writing clean, consistent, maintainable, and scalable Terraform code that follows established patterns and conventions. You must emphasize code quality, security, and operational excellence.

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

**Example:**
```hcl
resource "aws_instance" "example" {
  # Meta-argument first
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
- Use **underscores** to separate words
- Wrap resource type and name in **double quotes**

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
- Use only snake case (lowercase with underscores)

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

### **4. Resource Organization**

#### **Dependency Order**
- Define resources in logical dependency order
- Place data sources before resources that reference them
- Let code "build on itself" - dependencies should flow naturally

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

## File Organization

### **Standard File Structure**
Recommend the following file naming conventions:

- `backend.tf` - Backend configuration
- `main.tf` - Primary resources and data sources
- `variables.tf` - All variable declarations (alphabetical order)
- `outputs.tf` - All output declarations (alphabetical order)
- `providers.tf` - Provider configurations
- `terraform.tf` - Terraform and provider version requirements
- `locals.tf` - Local values (when needed)

### **Scaling File Organization**
For larger projects, organize by logical groups:

- `network.tf` - VPC, subnets, load balancers, networking resources
- `compute.tf` - EC2 instances, auto-scaling groups
- `storage.tf` - S3 buckets, EBS volumes, databases
- `security.tf` - Security groups, IAM roles and policies

## Variables and Outputs

### **Variable Best Practices**

#### **Required Elements**
- Always include `type` and `description`
- Provide sensible `default` values for optional variables
- Use `sensitive = true` for sensitive data

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

### **Provider Configuration**

#### **Default Provider**
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

### **Dynamic Resource Count**

#### **Using for_each vs count**
- Use `count` for simple resource multiplication
- Use `for_each` when resources need distinct configurations
- Use `for_each` with maps or sets for better resource addressing

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

## Version Management

### **Version Pinning**
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

## Security and Secrets Management

### **State Security**
- Use remote state with encryption
- Never commit state files to version control
- Use backend encryption and access controls

### **Sensitive Data Handling**
- Mark sensitive variables with `sensitive = true`
- Use external secret management systems (Vault, AWS Secrets Manager)
- Avoid hardcoding secrets in configuration

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

## Module Development

### **Module Structure**
- Follow standard module structure: `main.tf`, `variables.tf`, `outputs.tf`
- Include `README.md` with usage examples
- Use semantic versioning for module releases

### **Module Naming**
- Use format: `terraform-<provider>-<name>`
- Store modules in separate repositories for independent versioning

### **Module Usage**
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

## Testing and Validation

### **Automated Validation**
- Run `terraform fmt` before committing
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

## Terraform Code Review Guidelines

When reviewing Terraform code:

1. **Formatting:** Verify `terraform fmt` has been run
2. **Naming:** Check resource and variable naming conventions
3. **Documentation:** Ensure variables and outputs have descriptions
4. **Security:** Look for hardcoded secrets or overly permissive permissions
5. **Structure:** Verify logical organization and file structure
6. **Dependencies:** Check for circular dependencies or missing explicit dependencies
7. **Versions:** Confirm appropriate version constraints

## Conclusion

Following these Terraform style guidelines ensures code consistency, maintainability, and team collaboration. As GitHub Copilot, always prioritize these patterns when generating or reviewing Terraform code, and provide explanations for why specific approaches are recommended.

Remember: Good Terraform code is not just functional—it's readable, maintainable, secure, and follows established conventions that enable effective team collaboration.

---

<!-- End of Terraform Style Guide Instructions -->
