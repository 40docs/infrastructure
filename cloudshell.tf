resource "random_pet" "cloudshell_ssh_key_name" {
  count     = var.cloudshell ? 1 : 0
  prefix    = "cloudshell"
  separator = ""
}

resource "azapi_resource_action" "cloudshell_ssh_public_key_gen" {
  count                  = var.cloudshell ? 1 : 0
  type                   = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id            = azapi_resource.cloudshell_ssh_public_key[count.index].id
  action                 = "generateKeyPair"
  method                 = "POST"
  response_export_values = ["publicKey", "privateKey"]
}

resource "azapi_resource" "cloudshell_ssh_public_key" {
  count     = var.cloudshell ? 1 : 0
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = random_pet.cloudshell_ssh_key_name[count.index].id
  location  = azurerm_resource_group.azure_resource_group.location
  parent_id = azurerm_resource_group.azure_resource_group.id
}

resource "tls_private_key" "cloudshell_host_rsa" {
  #  count     = var.cloudshell ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "cloudshell_host_ecdsa" {
  #  count     = var.cloudshell ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

resource "tls_private_key" "cloudshell_host_ed25519" {
  #  count     = var.cloudshell ? 1 : 0
  algorithm = "ED25519"
}

resource "azurerm_virtual_network" "cloudshell_network" {
  count               = var.cloudshell ? 1 : 0
  name                = "cloudshell_network"
  address_space       = ["10.0.1.0/24"]
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  tags                = local.common.tags
}

resource "azurerm_subnet" "cloudshell_subnet" {
  count                = var.cloudshell ? 1 : 0
  name                 = "cloudshell_subnet"
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
  virtual_network_name = azurerm_virtual_network.cloudshell_network[count.index].name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "cloudshell_public_ip" {
  count               = var.cloudshell ? 1 : 0
  name                = "cloudshell_public_ip"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "cloudshell-${azurerm_resource_group.azure_resource_group.name}"
}

resource "azurerm_dns_cname_record" "cloudshell_public_ip_dns" {
  count               = var.cloudshell ? 1 : 0
  name                = "cloudshell"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ttl                 = 300
  record              = azurerm_public_ip.cloudshell_public_ip[count.index].fqdn
}

resource "azurerm_network_security_group" "cloudshell_nsg" {
  count               = var.cloudshell ? 1 : 0
  name                = "cloudshell_nsg"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "cloudshell_nic" {
  count               = var.cloudshell ? 1 : 0
  name                = "cloudshell_nic"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ip_configuration {
    name                          = "cloudshell_nic_configuration"
    subnet_id                     = azurerm_subnet.cloudshell_subnet[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.cloudshell_public_ip[count.index].id
  }
}

resource "azurerm_network_interface_security_group_association" "cloudshell_nic_nsg_association" {
  count                     = var.cloudshell ? 1 : 0
  network_interface_id      = azurerm_network_interface.cloudshell_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.cloudshell_nsg[count.index].id
}

resource "random_id" "random_id" {
  count = var.cloudshell ? 1 : 0
  keepers = {
    resource_group = azurerm_resource_group.azure_resource_group.name
  }
  byte_length = 8
}

resource "azurerm_storage_account" "cloudshell_storage_account" {
  count                             = var.cloudshell ? 1 : 0
  name                              = "cldshl${random_id.random_id[count.index].hex}"
  location                          = azurerm_resource_group.azure_resource_group.location
  resource_group_name               = azurerm_resource_group.azure_resource_group.name
  account_tier                      = "Standard"
  account_replication_type          = "LRS"
  infrastructure_encryption_enabled = true
  tags                              = local.standard_tags
}

resource "azurerm_managed_disk" "cloudshell_home_disk" {
  count                = var.cloudshell ? 1 : 0
  name                 = "cloudshell_home_disk"
  location             = azurerm_resource_group.azure_resource_group.location
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1024
  tags                 = local.standard_tags

  lifecycle {
    replace_triggered_by = [
      azurerm_linux_virtual_machine.cloudshell_vm
    ]
  }
}

resource "azurerm_managed_disk" "cloudshell_docker_disk" {
  count                = var.cloudshell ? 1 : 0
  name                 = "cloudshell_docker_disk"
  location             = azurerm_resource_group.azure_resource_group.location
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 512
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_managed_disk" "cloudshell_ollama_disk" {
  count                = var.cloudshell ? 1 : 0
  name                 = "cloudshell_ollama_disk"
  location             = azurerm_resource_group.azure_resource_group.location
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1024
  lifecycle {
    prevent_destroy = true
  }
}

locals {

  # GPU-enabled VM size detection
  # Azure VM sizes that have GPUs and require NVIDIA software installation
  gpu_enabled_vm_sizes = [
    "Standard_NC6s_v3",          # 1x V100
    "Standard_NC12s_v3",         # 2x V100
    "Standard_NC24s_v3",         # 4x V100
    "Standard_NC24ads_A100_v4",  # 1x A100
    "Standard_NC48ads_A100_v4",  # 2x A100
    "Standard_NC96ads_A100_v4",  # 4x A100
    "Standard_ND40rs_v2",        # 8x V100
    "Standard_ND96asr_v4",       # 8x A100
    "Standard_ND96amsr_A100_v4", # 8x A100 MIG
    "Standard_NV6",              # 1x M60
    "Standard_NV12",             # 2x M60
    "Standard_NV24",             # 4x M60
    "Standard_NV12s_v3",         # 1x M60
    "Standard_NV24s_v3",         # 2x M60
    "Standard_NV48s_v3",         # 4x M60
  ]

  # Determine if selected VM size has GPU
  cloudshell_vm_size = "Standard_D16s_v3" # 64GB RAM - upgraded from D8s_v3 for better performance and OOM prevention
  has_gpu            = var.cloudshell ? contains(local.gpu_enabled_vm_sizes, local.cloudshell_vm_size) : false
}

resource "azurerm_linux_virtual_machine" "cloudshell_vm" {
  count                 = var.cloudshell ? 1 : 0
  name                  = "cloudshell_vm"
  location              = azurerm_resource_group.azure_resource_group.location
  resource_group_name   = azurerm_resource_group.azure_resource_group.name
  network_interface_ids = [azurerm_network_interface.cloudshell_nic[count.index].id]

  # VM size configured in locals.cloudshell_vm_size - GPU software installed conditionally
  # Change local.cloudshell_vm_size to configure VM size and GPU capabilities
  # GPU VMs: Standard_NC*_v3, Standard_ND*_v2, Standard_NV*_v3 series
  # CPU VMs: Standard_D*s_v3, Standard_B*, Standard_F* series
  size = local.cloudshell_vm_size
  identity {
    type = "SystemAssigned"
  }
  custom_data = base64encode(
    templatefile("${path.module}/cloud-init/CLOUDSHELL.conf",
      {
        var_ssh_host_rsa_private     = tls_private_key.cloudshell_host_rsa.private_key_pem
        var_ssh_host_rsa_public      = tls_private_key.cloudshell_host_rsa.public_key_openssh
        var_ssh_host_ecdsa_private   = tls_private_key.cloudshell_host_ecdsa.private_key_pem
        var_ssh_host_ecdsa_public    = tls_private_key.cloudshell_host_ecdsa.public_key_openssh
        var_ssh_host_ed25519_private = tls_private_key.cloudshell_host_ed25519.private_key_pem
        var_ssh_host_ed25519_public  = tls_private_key.cloudshell_host_ed25519.public_key_openssh
        var_directory_tenant_id      = var.cloudshell_directory_tenant_id
        var_directory_client_id      = var.cloudshell_directory_client_id
        var_forticnapp_account       = var.forticnapp_account
        var_forticnapp_subaccount    = var.forticnapp_subaccount
        var_forticnapp_api_key       = var.forticnapp_api_key
        var_forticnapp_api_secret    = var.forticnapp_api_secret
        var_arm_subscription_id      = var.arm_subscription_id
        var_arm_client_id            = var.arm_client_id
        var_arm_client_secret        = var.arm_client_secret
        var_arm_tenant_id            = var.arm_tenant_id
        var_aks_resource_group       = azurerm_resource_group.azure_resource_group.name
        var_aks_cluster_name         = azurerm_kubernetes_cluster.kubernetes_cluster.name
        var_admin_username           = var.cloudshell_admin_username
        var_brave_api_key            = var.brave_api_key
        var_perplexity_api_key       = var.perplexity_api_key
        var_anthropic_api_key        = var.anthropic_api_key
        var_github_token             = var.github_token # Used to generate fresh registration token at runtime
        var_github_org               = var.github_org
        var_runner_group             = var.runner_group
        var_runner_labels            = var.runner_labels
        var_has_gpu                  = local.has_gpu
      }
    )
  )
  os_disk {
    name                 = "cloudshell_os_disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 256
  }
  source_image_reference {
    offer     = local.vm_image["cloudshell"].offer
    publisher = local.vm_image["cloudshell"].publisher
    sku       = local.vm_image["cloudshell"].sku
    version   = "latest"
  }
  computer_name                   = "CLOUDSHELL"
  admin_username                  = var.cloudshell_admin_username
  admin_password                  = var.hub_nva_password
  disable_password_authentication = false #tfsec:ignore:AVD-AZU-0039
  # admin_ssh_key {
  #   username   = var.cloudshell_admin_username
  #   public_key = azapi_resource_action.cloudshell_ssh_public_key_gen[count.index].output.publicKey
  # }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.cloudshell_storage_account[count.index].primary_blob_endpoint
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "cloudshell_home_disk_attachment" {
  count              = var.cloudshell ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.cloudshell_home_disk[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.cloudshell_vm[count.index].id
  lun                = 0
  caching            = "ReadWrite"
  create_option      = "Attach"
}

resource "azurerm_virtual_machine_data_disk_attachment" "cloudshell_docker_disk_attachment" {
  count              = var.cloudshell ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.cloudshell_docker_disk[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.cloudshell_vm[count.index].id
  lun                = 1
  create_option      = "Attach"
  caching            = "ReadWrite"
  #write_accelerator_enabled = true
}

resource "azurerm_virtual_machine_data_disk_attachment" "cloudshell_ollama_disk_attachment" {
  count              = var.cloudshell ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.cloudshell_ollama_disk[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.cloudshell_vm[count.index].id
  lun                = 2
  caching            = "ReadOnly"
  create_option      = "Attach"
  #write_accelerator_enabled = true
}

# Registration token is now generated at runtime using GitHub API
# This prevents token expiration issues during cloud-init execution
