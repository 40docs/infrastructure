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
  - **NEVER use `git push origin main`** - this will be rejected due to branch protection
  - **All deployments require PR approval** and CI/CD validation before merge
  - **Proper workflow**: Create feature branch → Make changes → Push feature branch → Create PR → Merge via GitHub
- **GitHub CLI**: Before running any `gh` commands, disable the pager with `export GH_PAGER=` to prevent pagination issues.
- **Pull Request Creation**: When creating a pull request, use a temporary file as the body of the pull request message instead of using a lengthy bash command.
- **Commit**: When creating a git commit, use a temporary file as the body of the commit message instead of using a lengthy bash command.
- **Temporary File Cleanup**: **ALWAYS clean up temporary files** created during Copilot operations to keep the repository clean.

## 🧹 Temporary File Management for Copilot

### **⚠️ CRITICAL: Always Clean Up Temporary Files**

Copilot frequently creates temporary files for commits, PRs, and processing. These files **MUST be deleted** after use to prevent accidental commits and maintain repository hygiene.

### **Common Copilot Temporary File Patterns:**

**Commit & PR Files:**
- `commit_message.md` / `commit_message.txt` - For detailed commit messages
- `pr_body.md` / `pr_body.txt` - For pull request descriptions
- `pr_body_temp.md` / `pr_body_temp.txt` - For temporary PR content
- `*_temp.md` / `*_temp.txt` - Any file with "_temp" suffix

**Processing & Draft Files:**
- `Copilot-Processing.md` - Processing status and task tracking
- `copilot_*.md` / `copilot_*.txt` - Copilot-generated content files
- `temp_*.md` / `temp_*.txt` - Files with "temp_" prefix
- `draft_*.md` / `draft_*.txt` - Draft content files

**Directory Patterns:**
- `.copilot/` - Copilot working directories
- `.ai_temp/` - AI assistant temporary directories

### **🔧 Cleanup Best Practices:**

1. **After Every Commit**: `rm commit_message.md commit_message.txt 2>/dev/null || true`
2. **After Every PR**: `rm pr_body*.md pr_body*.txt 2>/dev/null || true`
3. **Regular Cleanup**: `rm *_temp.* temp_*.* draft_*.* copilot_*.* 2>/dev/null || true`
4. **Check Before Push**: `git status` to verify no temporary files are staged

### **✅ Cleanup Command Examples:**

```bash
# Clean up commit message files
rm commit_message.md 2>/dev/null || true

# Clean up PR body files
rm pr_body*.md pr_body*.txt 2>/dev/null || true

# Clean up all temporary patterns
rm *_temp.* temp_*.* draft_*.* copilot_*.* 2>/dev/null || true

# Comprehensive cleanup (safe - ignores missing files)
rm commit_message.* pr_body*.* *_temp.* temp_*.* draft_*.* copilot_*.* 2>/dev/null || true
```

**Note**: These patterns are already included in `.gitignore`, but manual cleanup prevents workspace clutter and ensures no accidental staging.
- **Terraform**:
  - Do not run `terraform plan`, or `terraform apply` because terraform variables are initialized by github secrets during a workflow run.
- **Cloud-init**: Edit scripts in `cloud-init/` for VM setup.
- **CI/CD**: Merges to `main` via pull request trigger the deploy pipeline.
- **Testing**: Use security scanners (`tfsec`, `trivy`, `checkov`) before PR/merge.

## 🚨 CRITICAL: Protected Branch Workflow - LESSONS LEARNED

**⚠️ ABSOLUTE RULE: NEVER EXECUTE THESE COMMANDS ⚠️**

These commands will be **REJECTED** by GitHub and cause workflow violations:
```bash
# NEVER RUN THESE - THEY WILL FAIL:
git push origin main
git push --force origin main
git push -f origin main
git push --set-upstream origin main
# ANY direct push to main branch
```

### **Hard-Learned Lessons from Protected Branch Violations:**

1. **📋 RULE**: Even "simple documentation changes" require feature branches
   - **WHY**: No exceptions exist - ALL changes must go through PR process
   - **CONSEQUENCE**: Direct pushes get rejected with `GH013: Repository rule violations`

2. **📋 RULE**: AI assistants must follow the same workflow as humans
   - **WHY**: Branch protection doesn't distinguish between human and AI commits
   - **CONSEQUENCE**: Violations require manual recovery and workflow cleanup

3. **📋 RULE**: "Just this once" mindset leads to violations
   - **WHY**: Shortcuts bypass essential review and CI/CD validation
   - **CONSEQUENCE**: Forces time-consuming recovery and demonstrates poor practice

### **✅ CORRECT WORKFLOW - NO EXCEPTIONS:**

```bash
# Step 1: ALWAYS create feature branch first
git checkout -b feature/my-changes

# Step 2: Make your changes and commit
git add .
git commit -F commit_message.md  # Use temporary file for detailed messages

# Step 3: Clean up commit temporary files
rm commit_message.md 2>/dev/null || true

# Step 4: Push feature branch (this is ALLOWED)
git push origin feature/my-changes

# Step 5: Create pull request via GitHub CLI
export GH_PAGER=  # Disable pager first!
gh pr create --title "My Changes" --body-file pr_body.md

# Step 6: Clean up PR temporary files
rm pr_body.md 2>/dev/null || true

# Step 7: Merge via GitHub interface after approval
# (Never push directly to main)
```

### **🔧 Recovery from Protected Branch Violations:**

If you accidentally attempt to push to main:
1. **DON'T PANIC** - the push will be rejected (this is good!)
2. **Create feature branch**: `git checkout -b feature/recovery-branch`
3. **Reset main branch**: `git checkout main && git reset --hard origin/main`
4. **Push feature branch**: `git push origin feature/recovery-branch`
5. **Create PR**: Follow normal PR process

### **🎯 Key Takeaways:**
- **Branch protection rules exist for good reasons** - they enforce quality and collaboration
- **There are NO exceptions** - documentation, hotfixes, "simple changes" all need PRs
- **When in doubt, use feature branch** - it's always the safe choice
- **Recovery is possible** - but prevention through proper workflow is better

## Integration Points
- **Azure**: Auth via Azure CLI or GitHub Actions (`azure/login`).
- **GitHub Actions**: See `.github/workflows/infrastructure.yml` for build/deploy logic.
- **GitHub CLI**: Always run `export GH_PAGER=` before using `gh` commands to disable pager and prevent terminal blocking.
- **External Tools**: Security scanning tools are recommended but not enforced.

## Azure Kubernetes Service (AKS) Cluster

### **🎯 Cluster Information**
- **Cluster Name**: `40docs_k8s-cluster_eastus`
- **Resource Group**: `40docs`
- **Location**: `eastus`
- **Kubernetes Version**: `1.31.10`
- **Status**: Managed through Terraform in `spoke-k8s_cluster.tf`

### **🔧 Getting Kubeconfig Access**

To connect to the AKS cluster for kubectl operations, use the Azure CLI:

```bash
# Standard user credentials (recommended)
az aks get-credentials --resource-group 40docs --name 40docs_k8s-cluster_eastus --overwrite-existing

# Admin credentials (for cluster administration)
az aks get-credentials --resource-group 40docs --name 40docs_k8s-cluster_eastus --admin --overwrite-existing

# Save to specific kubeconfig file
az aks get-credentials --resource-group 40docs --name 40docs_k8s-cluster_eastus --file ~/.kube/aks-config
```

### **✅ Verification Commands**

After getting credentials, verify connectivity:
```bash
kubectl config current-context        # Should show: 40docs_k8s-cluster_eastus
kubectl get nodes                     # List cluster nodes
kubectl get namespaces                # List available namespaces
kubectl get pods --all-namespaces     # List all pods across namespaces
```

### **🚀 Common AKS Operations**

- **Application Deployments**: Managed via Terraform files `spoke-k8s_application-*.tf`
- **Infrastructure Changes**: All cluster modifications should go through Terraform and CI/CD pipeline
- **Direct kubectl**: Use for monitoring, debugging, and read-only operations
- **Secrets Management**: Handled through Terraform and Azure Key Vault integration

### **⚠️ Important Notes**
- **Never manually modify cluster resources** that are managed by Terraform (deployments, services, ingress)
- **Use kubectl for troubleshooting and monitoring** only
- **All persistent changes** must go through the Terraform + CI/CD workflow
- **Feature branch workflow** applies to any infrastructure changes

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
