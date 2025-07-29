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
- **Terraform**:
  - `terraform init` (initialize)
  - `terraform plan -out=tfplan` (preview)
  - `terraform apply tfplan` (deploy)
- **Cloud-init**: Edit scripts in `cloud-init/` for VM setup.
- **CI/CD**: Push to `main` triggers deploy pipeline.
- **Testing**: Use security scanners (`tfsec`, `trivy`, `checkov`) before PR/merge.

## Integration Points
- **Azure**: Auth via Azure CLI or GitHub Actions (`azure/login`).
- **GitHub Actions**: See `.github/workflows/infrastructure.yml` for build/deploy logic.
- **External Tools**: Security scanning tools are recommended but not enforced.

## Project-Specific Conventions
- **Variable Definitions**: All variables in `variables.tf` must have descriptions; sensitive variables must be marked.
- **Adding Applications**: Create a new `spoke-k8s_application-<name>.tf` file, follow existing patterns, update variables/outputs, and push to `main`.
- **Cloud-init**: Use YAML syntax; avoid mixing shell and cloud-init mounts. If using `mounts:`, ensure all fields are strings.
- **CI/CD Secrets**: All secrets are injected via GitHub Actions, not stored in code.

## Key Files & Directories
- `cloud-init/` — VM bootstrap scripts
- `spoke-k8s_application-*.tf` — App deployments
- `hub-network.tf`, `spoke-network.tf` — Network
- `.github/workflows/infrastructure.yml` — CI/CD pipeline
- `variables.tf` — All input variables

## Example: Adding a New Application
1. Create `spoke-k8s_application-<name>.tf`.
2. Define resources using existing patterns.
3. Update `variables.tf` and outputs as needed.
4. Commit and push to `main` to trigger deployment.

## Troubleshooting terraform
1. run `terraform fmt` to format files
2. run `terraform validate` to check syntax
3. do not run `terraform plan` to preview changes since variables are initialized from github secrets in a workflow.
4. do not run `terraform apply` to deploy changes since this is done automatically by the CI/CD pipeline.
---

For more details, see `README.md` and inline comments in `.tf` files.
