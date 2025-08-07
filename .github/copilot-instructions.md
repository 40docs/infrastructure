# Copilot Instructions for 40docs Infrastructure

## Project Overview
- **Purpose**: Automates Azure infrastructure and Kubernetes application deployment using Terraform, with modular `.tf` files for each major component.
- **Cloud-init**: VM bootstrap scripts are in `cloud-init/`.
- **CI/CD**: GitHub Actions (`.github/workflows/infrastructure.yml`) runs `terraform plan`/`apply` on changes to `.tf` or `cloud-init/*` files.

## Architecture & Patterns
- **File Structure**:
  - Each logical component (network, resource group, hub, spoke, k8s cluster, apps) has its own `.tf` file.
  - Application deployments: `spoke-k8s_application-*.tf`
  - Network: `hub-network.tf`, `spoke-network.tf`
  - VM bootstrap: `cloud-init/`
- **No deep module nesting**: Prefer flat, readable structure.
- **Sensitive Data**: Never commit secrets; use variables and mark as `sensitive = true`.
- **Outputs**: Only expose non-sensitive outputs.
- **Security**: Use private subnets, encryption, least-privilege IAM. Scan with `tfsec`, `trivy`, or `checkov`.
- **Documentation**: Document complex logic inline in `.tf` files.


## Developer Workflow
- **Branch Protection**: The `main` branch is protected. **All changes must be made via a pull request. Direct pushes to `main` are not allowed.**
  - **ALWAYS create a feature branch** for any changes (e.g., `git checkout -b feature/cloudshell-fix`)
  - **Never commit directly to main** - this will be rejected by GitHub
  - **All deployments require PR approval** and CI/CD validation before merge
- **GitHub CLI**: Before running any `gh` commands, disable the pager with `export GH_PAGER=` to prevent pagination issues.
- **Pull Request Creation**: When creating a pull request, use a temporary file as the body of the pull request message instead of using a lengthy bash command.
- **Commit**: When creating a git commit, use a temporary file as the body of the commit message instead of using a lengthy bash command.
- **Terraform**:
  - Do not run `terraform plan`, or `terraform apply` because terraform variables are initialized by github secrets during a workflow run.
- **Cloud-init**: Edit scripts in `cloud-init/` for VM setup.
- **CI/CD**: Merges to `main` via pull request trigger the deploy pipeline.
- **Testing**: Use security scanners (`tfsec`, `trivy`, `checkov`) before PR/merge.

## Integration Points
- **Azure**: Auth via Azure CLI or GitHub Actions (`azure/login`).
- **GitHub Actions**: See `.github/workflows/infrastructure.yml` for build/deploy logic.
- **GitHub CLI**: Always run `export GH_PAGER=` before using `gh` commands to disable pager and prevent terminal blocking.
- **External Tools**: Security scanning tools are recommended but not enforced.

## Project-Specific Conventions
- **Variable Definitions**: All variables in `variables.tf` must have descriptions; sensitive variables must be marked.
- **Adding Applications**: Create a new `spoke-k8s_application-<name>.tf` file, follow existing patterns, update variables/outputs, and **create a feature branch + pull request** to deploy changes.
- **Cloud-init**: Use YAML syntax; avoid mixing shell and cloud-init mounts. If using `mounts:`, ensure all fields are strings.
- **CI/CD Secrets**: All secrets are injected via GitHub Actions, not stored in code.

## Key Files & Directories
- `cloud-init/` — VM bootstrap scripts
- `spoke-k8s_application-*.tf` — App deployments
- `hub-network.tf`, `spoke-network.tf` — Network
- `.github/workflows/infrastructure.yml` — CI/CD pipeline
- `variables.tf` — All input variables

## Example: Adding a New Application
1. **Create a feature branch**: `git checkout -b feature/add-new-app`
2. Create `spoke-k8s_application-<name>.tf`.
3. Define resources using existing patterns.
4. Update `variables.tf` and outputs as needed.
5. **Create a pull request** to merge changes into `main` and trigger deployment.

## Troubleshooting and Testing terraform
1. run `terraform fmt` to format files
2. run `terraform validate` to check syntax
3. Do not run `terraform init`, instead run `terraform init -backend=false` to initialize without backend since provider variables are initialized from github secrets in a workflow.
4. run `lacework iac scan` to scan for security issues and suggest relevant fixes to the terraform plan.
5. do not run `terraform plan` to preview changes since variables are initialized from github secrets in a workflow.
6. do not run `terraform apply` to deploy changes since this is done automatically by the CI/CD pipeline.

## Terraform Code Standards
- **Variable Naming**: All variables must use `snake_case` (underscores), never `kebab-case` (hyphens)
- **Resource Naming**: Resource names should use underscores for consistency with Terraform conventions
- **Variable References**: Always use `var.variable_name` format, never `var.variable-name`
- **Code Style**: Follow HashiCorp Terraform style guide and run `terraform fmt` before committing
---

For more details, see `README.md` and inline comments in `.tf` files.
