# 40docs Infrastructure

This repository automates the deployment and management of Azure infrastructure and Kubernetes applications using Terraform. It is designed for modularity, security, and maintainability, with CI/CD managed via GitHub Actions.

## Architecture

- **Terraform Modules**: Each major infrastructure component (network, resource group, hub, spoke, k8s cluster, applications) is defined in its own `.tf` file for clarity and separation.
- **Cloud-init**: VM initialization scripts are stored in `cloud-init/`.
- **CI/CD**: `.github/workflows/infrastructure.yml` automates Terraform plan/apply on changes to `.tf` or `cloud-init/*` files.
- **Sensitive Data**: Secrets and credentials are never committed; use environment variables and mark sensitive variables/outputs as `sensitive = true`.

## Developer Workflow

1. **Initialize**: Run `terraform init` in the repo root.
2. **Plan**: Use `terraform plan -out=tfplan` to preview changes.
3. **Apply**: Deploy with `terraform apply tfplan`.
4. **Cloud-init**: Edit files in `cloud-init/` for VM bootstrapping.
5. **CI/CD**: Push changes to `main` to trigger automated workflows.

## Conventions & Patterns

- Use separate `.tf` files for each logical component. Avoid deep module nesting.
- Only expose non-sensitive outputs; mark sensitive outputs as `sensitive = true`.
- Use private subnets, encryption, and least-privilege IAM roles. Scan configs with `tfsec`, `trivy`, or `checkov`.
- Document complex logic and design decisions directly in `.tf` files.

## Integration Points

- **Azure**: Auth via Azure CLI or GitHub Actions (`azure/login`).
- **GitHub Actions**: See `.github/workflows/infrastructure.yml` for build/deploy logic.
- **External Tools**: Security scanning tools (`tfsec`, `trivy`, `checkov`) recommended.

## Key Files

- `cloud-init/` — VM initialization scripts
- `spoke-k8s_application-*.tf` — Application deployments
- `hub-network.tf`, `spoke-network.tf` — Network definitions
- `.github/instructions.md` — Terraform conventions
- `.github/workflows/infrastructure.yml` — CI/CD pipeline

## Example: Adding a New Application

1. Create `spoke-k8s_application-<name>.tf` for the new app.
2. Define resources using existing patterns.
3. Update variables and outputs as needed.
4. Commit and push to `main` to trigger deployment.
