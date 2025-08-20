# FortiWeb NVA Azure Deployment Technical Analysis

## Overview

This document explains how the FortiWeb Web Application Firewall (WAF) is deployed as a Network Virtual Appliance (NVA) in Azure using cloud-init configuration, based on the infrastructure defined in `hub-nva.tf` and the cloud-init template `cloud-init/fortiweb.conf`.

## Infrastructure Architecture

### Hub-Spoke Network Topology
The FortiWeb NVA operates as the central security enforcement point in a hub-spoke network architecture:

- **Hub Network**: Contains the FortiWeb NVA for centralized security inspection
- **Spoke Network**: Houses protected applications (AKS cluster, applications)
- **Traffic Flow**: All spoke-to-internet and internet-to-spoke traffic flows through FortiWeb

### Virtual Machine Configuration

```terraform
# From hub-nva.tf
resource "azurerm_linux_virtual_machine" "hub_nva_virtual_machine" {
  name                            = "hub-nva_virtual_machine"
  computer_name                   = "hub-nva"
  admin_username                  = var.hub_nva_username
  disable_password_authentication = false
  admin_password                  = var.hub_nva_password
  size                            = var.production_environment ? local.vm_image[var.hub_nva_image].size : local.vm_image[var.hub_nva_image].size-dev
}
```

### Network Interface Configuration
The FortiWeb VM has two network interfaces:

1. **External Interface (port1)**: Connected to hub external subnet
   - Primary management IP for administration
   - Multiple VIP addresses for different applications (docs, dvwa, ollama, video, extractor)
   - Public IP assignments for internet access

2. **Internal Interface (port2)**: Connected to hub internal subnet
   - Static IP: 10.0.0.36
   - IP forwarding enabled for traffic routing
   - Gateway to spoke networks

## Cloud-Init Configuration Analysis

### Configuration Structure
The cloud-init template uses FortiWeb's native cloud-init support with JSON format:

```json
{
  "cloud-initd": "enable",
  "usr-cli": '<CLI_COMMANDS>',
  "HaAzureInit": "disable"
}
```

### System Global Configuration

```bash
config system global
  set admin-sport ${var_config_system_global_admin_sport}
end
```
- Configures the administrative port for HTTPS GUI access
- Variable substitution from Terraform template

### Interface Configuration

```bash
config system interface
  edit "port2"
    set allowaccess ping https
  next
end
```
- Enables ping and HTTPS access on the internal interface (port2)
- Allows management access from internal networks

### Routing Configuration

```bash
config router static
  edit 1
    set dst ${var_spoke_virtual_network_address_prefix}
    set gateway ${var_spoke_default_gateway}
    set device port2
  next
  edit 2
    set gateway ${var_hub_external_subnet_gateway}
    set device port1
  next
end

config router setting
  set ip-forward enable
end
```

**Static Routes**:
1. **Route 1**: Directs spoke network traffic (via port2) to internal gateway
2. **Route 2**: Default route for internet traffic (via port1) to external gateway
3. **IP Forwarding**: Enables traffic routing between interfaces

### Firewall Address Objects

The configuration defines address objects for network segments and VIPs:

```bash
config system firewall address
  edit "spoke-aks-node-ip"
    set ip-address-value ${var_spoke_aks_node_ip}
  next
  edit "hub-nva-vip-docs"
    set ip-address-value ${var_hub_nva_vip_docs}
  next
  edit "kubernetes_nodes"
    set type ip-netmask
    set ip-netmask ${var_spoke_aks_network}
  next
end
```

**Address Objects**:
- Individual VIP addresses for each application
- AKS node IP for outbound traffic
- Kubernetes nodes network range
- Internet object for external access

### Service Definitions

```bash
config system firewall service
  edit "http"
    set destination-port-min 80
    set destination-port-max 80
  next
  edit "https"
    set destination-port-min 443
    set destination-port-max 443
  next
  edit "ICMP"
    set protocol ICMP
  next
end
```

Defines standard services for HTTP, HTTPS, and ICMP traffic.

### Firewall Policy Configuration

#### Policy Structure
```bash
config system firewall firewall-policy
  set default-action deny
  config firewall-policy-match-list
    # Individual policies
  end
end
```

#### Key Policies

1. **Outbound AKS Traffic** (Policies 1-3):
   ```bash
   edit 1
     set in-interface port2
     set out-interface port1
     set src-address spoke-aks-node-ip
     set dest-address internet
     set service http
     set action accept
   next
   ```
   - Allows AKS nodes to access internet for HTTP/HTTPS
   - Includes ICMP for connectivity checks

2. **Inbound Application Traffic** (Policies 4-15):
   ```bash
   edit 4
     set in-interface port1
     set src-address internet
     set dest-address hub-nva-vip-docs
     set service http
     set action accept
   next
   ```
   - Allows internet access to each application VIP
   - Separate rules for HTTP and HTTPS per application
   - Applications: docs, dvwa, ollama, video, artifacts, extractor

3. **General Kubernetes Outbound** (Policy 16):
   ```bash
   edit 16
     set in-interface port2
     set out-interface port1
     set src-address kubernetes_nodes
     set dest-address internet
     set service all
     set action accept
   next
   ```
   - Allows all Kubernetes nodes internet access

### SNAT Configuration

```bash
config system firewall snat-policy
  edit "spoke-aks-node-to-internet-snat"
    set source-start ${var_spoke_virtual_network_subnet}
    set source-end ${var_spoke_virtual_network_netmask}
    set out-interface port1
    set trans-to-ip ${var_hub_nva_vip_docs}
  next
end
```

**Source NAT Policy**:
- Translates spoke network traffic to docs VIP address
- Enables spoke networks to access internet through FortiWeb
- Uses docs VIP as the translated IP address

### Security Features

#### OWASP Top 10 Compliance
```bash
config system advanced
  set owasp-top10-compliance enable
end

config system dashboard-widget
  # OWASP Top 10 dashboard widget configuration
end
```

#### Feature Visibility
```bash
config system feature-visibility
  set ftp-security enable
  set acceleration-policy enable
  set web-cache enable
  set wvs enable
  set api-gateway enable
  set firewall enable
  set wad enable
  set fortigate-integration enable
  set recaptcha enable
end
```

Enables comprehensive security features including:
- Web Vulnerability Scanner (WVS)
- API Gateway protection
- reCAPTCHA integration
- FortiGate integration capabilities

### Certificate Management

```bash
config system certificate local
  edit "self-signed-cert"
    set certificate "${var_certificate}"
    set private-key "${var_privatekey}"
    set passwd ENC m8eWJTISWrN/JBB9KSp7kOFMNoo=
  next
end
```

**SSL Certificate Configuration**:
- Uses Terraform-generated self-signed certificate
- Certificate and private key injected via template variables
- Encrypted password for certificate protection

### Logging Configuration

```bash
config log disk
  set severity notification
end

config log traffic-log
  set status enable
  set packet-log enable
end
```

**Logging Features**:
- Disk logging at notification level
- Traffic logging with packet capture enabled
- Comprehensive audit trail for security events

## Traffic Flow Analysis

### Inbound Internet Traffic
1. **Internet** → **FortiWeb port1** (external interface)
2. **FortiWeb firewall policies** evaluate traffic against VIP addresses
3. **Allowed traffic** forwarded to **port2** (internal interface)
4. **Internal routing** directs traffic to spoke network applications

### Outbound Spoke Traffic
1. **Spoke networks** → **FortiWeb port2** (internal interface)
2. **Static routing** and **SNAT policy** process outbound traffic
3. **FortiWeb firewall policies** evaluate outbound requests
4. **Approved traffic** forwarded via **port1** to internet

### Security Inspection
- All traffic passes through FortiWeb's WAF engine
- OWASP Top 10 protection enabled
- API gateway and web vulnerability scanning active
- Comprehensive logging and monitoring

## Azure Integration Considerations

### VM Specifications
- **Minimum Requirements**: 2 vCPUs, 8GB RAM
- **Recommended MTU**: 1,400 bytes for Azure networking
- **Network Security Groups**: Default ports 22, 80, 443, 8080, 8443, 514

### High Availability Options

#### Current Deployment (Single Instance)
⚠️ **Standard Deployment**: Single instance configuration (`hub-nva.tf`)
- Uses availability set instead of availability zones
- Single point of failure for all application traffic
- No automated failover or load balancing
- Simpler configuration and management

#### Enhanced High Availability Option
✅ **HA Deployment Available**: Multi-zone configuration (`hub-nva-ha-enhanced.tf`)
- **Multi-Zone Deployment**: 2 instances across Azure availability zones (Zone 1 & Zone 2)
- **Azure Standard Load Balancer**: Traffic distribution with health probes
- **Automated Failover**: Health monitoring with automatic traffic redirection
- **Enhanced Monitoring**: Comprehensive alerting and diagnostics

### Marketplace Integration
- Deploys from Azure Marketplace
- BYOL or PAYG licensing options available
- Automated acceptance of marketplace terms via Terraform

## CLI Command Reference

Based on FortiWeb 8.0.0 CLI documentation, key command categories include:

### Configuration Commands
- `config system global` - Global system settings
- `config system interface` - Network interface configuration
- `config router static` - Static routing configuration
- `config system firewall` - Firewall policies and rules

### Diagnostic Commands
- `diagnose` - System diagnostics and troubleshooting
- `get` - Retrieve system information
- `show` - Display current configurations
- `execute` - Perform system actions (backup, update)

### Advanced Features
- Web Application Firewall (WAF) configuration
- API protection and gateway features
- Certificate management
- User authentication and RBAC

## Deployment Timeline

**Typical Deployment**: ~20 minutes for complete VM provisioning and configuration
- Azure VM creation and marketplace image deployment
- Cloud-init execution and FortiWeb configuration
- Network interface configuration and routing setup
- Security policy application and service startup

## Security Recommendations

1. **Enable High Availability**: Deploy multiple FortiWeb instances across availability zones
2. **Implement Load Balancing**: Add Azure Standard Load Balancer for traffic distribution
3. **Network Segmentation**: Review and optimize firewall policies for least privilege
4. **Certificate Management**: Implement proper SSL certificate lifecycle management
5. **Monitoring**: Enable comprehensive logging and integrate with SIEM solutions
6. **Regular Updates**: Maintain current FortiWeb firmware and security signatures

## High Availability Architecture (Enhanced Option)

### HA Infrastructure Components

The enhanced HA configuration (`hub-nva-ha-enhanced.tf`) addresses critical availability limitations with enterprise-grade resilience:

#### Multi-Zone Deployment
```terraform
# Two FortiWeb instances across availability zones
nva_instances = [
  {
    name       = "primary"
    zone       = "1"
    private_ip = "10.0.0.20"
    priority   = 100
  },
  {
    name       = "secondary" 
    zone       = "2"
    private_ip = "10.0.0.21"
    priority   = 90
  }
]
```

**Zone Distribution**:
- **Primary Instance**: Azure Zone 1 (10.0.0.20)
- **Secondary Instance**: Azure Zone 2 (10.0.0.21)
- **Fault Tolerance**: Survives single zone failure
- **VM Sizing**: Standard_F4s_v2 (production) / Standard_F2s_v2 (dev)

#### Azure Standard Load Balancer
```terraform
resource "azurerm_lb" "hub_nva_lb" {
  sku      = "Standard"
  sku_tier = "Regional"
  
  # VIP frontend configurations for each application
  dynamic "frontend_ip_configuration" {
    for_each = { for vip in local.vip_configs : vip.name => vip if vip.enabled }
  }
}
```

**Load Balancer Features**:
- **Frontend IPs**: Dedicated VIP for each application (docs, dvwa, ollama, video, extractor)
- **Backend Pools**: Application-specific pools for traffic isolation
- **Health Probes**: HTTP health checks on port 8080 (/healthcheck endpoint)
- **Load Distribution**: Source IP Protocol persistence for session consistency
- **Floating IP**: Required for FortiWeb VIP handling

#### Health Monitoring and Failover
```terraform
resource "azurerm_lb_probe" "hub_nva_health_probe" {
  protocol            = "Http"
  port                = 8080
  request_path        = "/healthcheck"
  interval_in_seconds = 30
  number_of_probes    = 3
}
```

**Health Check Configuration**:
- **Endpoint**: `/healthcheck` on port 8080
- **Frequency**: Every 30 seconds
- **Failure Threshold**: 3 consecutive failures
- **Automatic Failover**: Traffic redirected to healthy instances

### HA Cloud-Init Configuration

The enhanced cloud-init (`cloud-init/fortiweb-ha.conf`) provides comprehensive HA initialization:

#### Multi-Part Configuration Structure
```yaml
Content-Type: multipart/mixed; boundary="===============1234567890=="
MIME-Version: 1.0

# Part 1: Shell script for HA cluster setup
Content-Type: text/x-shellscript

# Part 2: Cloud-config for system configuration  
Content-Type: text/cloud-config
```

#### HA Cluster Configuration
```bash
configure_ha_cluster() {
  local role="${var_instance_role}"
  local priority="${var_cluster_priority}"
  local peer_ip="${var_peer_ip}"
  
  # FortiWeb HA configuration
  cat > /tmp/ha_config.conf << EOF
config system ha
  set mode active-passive
  set group-name "40docs-cluster"
  set priority $priority
  set override enable
  set unicast-hb enable
  set unicast-hb-peerip $peer_ip
  set hb-interval 10
  set hb-lost-threshold 3
end
EOF
}
```

**Cluster Configuration**:
- **Mode**: Active-Passive for failover
- **Group Name**: "40docs-cluster"
- **Heartbeat**: Unicast between instances (10s interval)
- **Failover**: 3 missed heartbeats trigger failover
- **Priority**: Primary (100), Secondary (90)

#### Health Check Endpoint
```bash
configure_health_check() {
  cat > /tmp/health_config.conf << EOF
config system health-check
  set status enable
  set port 8080
  set uri "/healthcheck"
  set method GET
  set response-code 200
  set response-body "OK"
end
EOF
}
```

#### Enhanced Monitoring Service
```bash
# Systemd service for continuous health monitoring
/usr/local/bin/fortiweb-monitor.sh:
- Health checks every 30 seconds
- Memory and CPU usage reporting
- Comprehensive logging to /var/log/fortiweb-monitor.log
- Automatic remediation capabilities
```

### HA Traffic Flow

#### Inbound Traffic (HA Mode)
1. **Internet** → **Azure Load Balancer** (VIP frontends)
2. **Load Balancer** → **Active FortiWeb Instance** (based on health probes)
3. **FortiWeb Policies** → **Application Backend** (via spoke network)
4. **Failover**: Automatic redirect to secondary instance on primary failure

#### Health Monitoring Flow
1. **Load Balancer Probe** → **FortiWeb /healthcheck** endpoint
2. **Health Status** → **Backend Pool Membership** updates
3. **Instance Failure** → **Traffic Redirection** to healthy instance
4. **Cluster Sync** → **Configuration Synchronization** between instances

### Monitoring and Alerting

#### Azure Monitor Integration
```terraform
resource "azurerm_monitor_diagnostic_setting" "hub_nva_lb_diagnostics" {
  target_resource_id         = azurerm_lb.hub_nva_lb[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.platform_workspace.id
  
  enabled_metric {
    category = "AllMetrics"
  }
}
```

#### Critical Health Alerts
```terraform
resource "azurerm_monitor_metric_alert" "hub_nva_health_alert" {
  description = "Alert when FortiWeb NVA instances are unhealthy"
  severity    = 1
  
  criteria {
    metric_name = "DipAvailability" 
    threshold   = 50  # Alert if <50% backends healthy
  }
}
```

**Alert Configuration**:
- **Metric**: Backend availability (DipAvailability)
- **Threshold**: <50% healthy backends
- **Frequency**: 1-minute evaluation window
- **Action**: Integration with Azure Action Groups

### Deployment Considerations

#### Resource Dependencies
```terraform
depends_on = [
  azurerm_network_interface.hub_nva_external_network_interface,
  azurerm_linux_virtual_machine.hub_nva_virtual_machine
]
```
- **Conflict Resolution**: Single-instance resources destroyed before HA deployment
- **IP Address Management**: HA uses separate IP ranges (10.0.0.20-21) vs single instance (10.0.0.36)
- **Random Suffix**: Prevents name conflicts from failed deployments

#### Configuration Toggle
The HA deployment is controlled by the `var.hub_nva_high_availability` variable:
- **false**: Standard single-instance deployment (`hub-nva.tf`)
- **true**: Enhanced HA deployment (`hub-nva-ha-enhanced.tf`)

### HA Benefits

**🔧 Operational Resilience**:
- Zero downtime during single zone failures
- Automated failover without manual intervention
- Health monitoring with comprehensive alerting

**⚡ Performance Optimization**:
- Load distribution across multiple instances
- Session persistence for application consistency
- Enhanced monitoring and diagnostics

**🛡️ Security Enhancement**:
- Redundant security inspection capabilities
- Continuous availability of WAF protection
- No single points of failure in security architecture

**📊 Monitoring & Observability**:
- Azure Monitor integration with metrics and alerts
- Custom health monitoring services on each instance
- Comprehensive logging and audit trails

## Conclusion

The FortiWeb NVA deployment provides comprehensive web application firewall protection for the 40docs platform through automated Azure deployment and cloud-init configuration. 

**Standard Deployment** offers essential security capabilities with simplified management for development and small-scale environments.

**Enhanced HA Deployment** provides enterprise-grade resilience with multi-zone availability, automated failover, and comprehensive monitoring for production environments requiring maximum uptime and fault tolerance.