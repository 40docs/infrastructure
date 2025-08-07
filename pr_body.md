## CloudShell VM /home LUN Preservation Issue Fix

### Problem
The CloudShell Azure virtual machine was incorrectly preserving `/home` directory contents across VM re-deployments. The `/home` LUN0 should be completely erased after each re-deploy to ensure a clean environment.

### Root Cause
While the cloud-init configuration was set to force format the `/home` disk (`format_and_mount 0 homefs /home yes`), the Azure managed disk was persisting across VM updates rather than being recreated, leading to data preservation.

### Solution Implemented

#### 1. Terraform Managed Disk Lifecycle Enhancement
- Added `replace_triggered_by` lifecycle rule to force disk recreation when VM is redeployed
- Ensures the `/home` disk is completely fresh on each deployment

#### 2. Cloud-init Formatting Improvement  
- Enhanced formatting logic with `wipefs -a "$dev"` to completely wipe existing filesystems
- Removes any remnant filesystem signatures before formatting

### Technical Changes

**Terraform (`cloudshell.tf`):**
```terraform
resource "azurerm_managed_disk" "cloudshell_home_disk" {
  # ... existing configuration ...
  lifecycle {
    replace_triggered_by = [
      azurerm_linux_virtual_machine.cloudshell_vm
    ]
  }
}
```

**Cloud-init (`cloud-init/CLOUDSHELL.conf`):**
```bash
if [[ "$always_format" == "yes" ]]; then
  echo "[INFO] Formatting $dev (forced) for $mount_point ..."
  wipefs -a "$dev" 2>/dev/null || true  # Complete wipe
  parted -s "$dev" mklabel gpt mkpart primary ext4 0% 100%
  mkfs.ext4 -F "$part" -L "$label"
```

### Expected Results
- ✅ `/home` LUN 0 completely erased on each VM re-deployment
- ✅ No persistence of `/home` directory contents across deployments  
- ✅ Docker and Ollama disks remain preserved as intended
- ✅ Clean CloudShell environment on every deployment

### Testing
This change should be tested by:
1. Deploying the CloudShell VM with some test files in `/home`
2. Triggering a VM re-deployment via Terraform
3. Verifying that `/home` is empty and clean after re-deployment
4. Confirming Docker and Ollama volumes retain their data

/cc @infrastructure-team
