# Terraform vSphere VM Module with Infoblox IPAM Integration

This Terraform module enables the deployment of virtual machines in VMware vSphere environments with advanced features for datastore selection, network configuration, and Infoblox IPAM integration for IP address allocation and DNS management.

## Features

- **Intelligent Resource Selection**: Automatically selects datastores with the most free space
- **Multi-OS Support**: Handles customization for different operating systems (RHEL, Ubuntu, Windows)
- **Advanced Storage Options**:
  - Datastore filtering using regex patterns
  - Datastore cluster support
  - Multi-disk configuration
- **Infoblox IPAM Integration**:
  - Dynamic IP allocation from Infoblox networks
  - Reserved IP support
  - DNS record creation (A and PTR records)
  - Extensible attributes support
- **Enterprise-Grade Organization**:
  - Resource pool placement
  - VM folder organization
  - Comprehensive tagging and annotations

## Prerequisites

- Terraform v1.0+
- vSphere environment with vCenter
- vSphere provider v2.0+
- Infoblox provider v2.0+
- Infoblox Grid with API access
- VM templates for supported operating systems

## Installation

1. Add the module to your Terraform configuration:

```hcl
module "vsphere_vm" {
  source = "path/to/vsphere-vm"
  
  # Required parameters
  vsphere_server    = "vcenter.example.com"
  datacenter_id     = "datacenter-name"
  cluster_id        = "cluster-name"
  template_id       = "template-name"
  vm_name           = "new-vm-name"
  os_family         = "linux"
  network_id        = "network-name"
  
  # Optional parameters with defaults
  num_cpus          = 2
  memory_mb         = 4096
  
  # ... additional parameters as needed
}
```

2. Initialize Terraform:

```bash
terraform init
```

## Usage Examples

### Basic Linux VM with DHCP

```hcl
module "linux_web_server" {
  source = "./vsphere-vm"
  
  vsphere_server    = "vcenter.example.com"
  datacenter_id     = "DC01"
  cluster_id        = "Cluster01"
  template_id       = "rhel8-template"
  vm_name           = "web-server-01"
  os_family         = "linux"
  network_id        = "VM Network"
  folder_path       = "Production/Web Servers"
  
  num_cpus          = 2
  memory_mb         = 4096
  
  additional_disks  = [
    {
      label    = "data"
      size_gb  = 100
    }
  ]
}
```

### Windows VM with Static IP

```hcl
module "windows_app_server" {
  source = "./vsphere-vm"
  
  vsphere_server           = "vcenter.example.com"
  datacenter_id            = "DC01"
  cluster_id               = "Cluster01"
  template_id              = "win2019-template"
  vm_name                  = "app-server-01"
  os_family                = "windows"
  network_id               = "VM Network"
  
  num_cpus                 = 4
  memory_mb                = 8192
  
  use_static_ip            = true
  static_ip_address        = "10.0.0.100"
  subnet_mask              = "24"
  default_gateway          = "10.0.0.1"
  dns_servers              = ["10.0.0.2", "10.0.0.3"]
  dns_suffixes             = ["example.com"]
  domain                   = "example.com"
  
  windows_admin_password   = var.admin_password
  domain_admin_user        = "administrator"
  domain_admin_password    = var.domain_admin_password
  
  additional_disks         = [
    {
      label    = "data"
      size_gb  = 200
      thin_provisioned = false
    }
  ]
}
```

### VM with Infoblox IPAM Integration

```hcl
module "app_server_with_ipam" {
  source = "./vsphere-vm"
  
  vsphere_server        = "vcenter.example.com"
  datacenter_id         = "DC01"
  cluster_id            = "Cluster01"
  template_id           = "rhel8-template"
  vm_name               = "app-server-02"
  os_family             = "linux"
  network_id            = "VM Network"
  
  num_cpus              = 4
  memory_mb             = 8192
  
  # Infoblox IPAM integration
  use_infoblox          = true
  infoblox_grid_host    = "infoblox.example.com"
  infoblox_username     = var.infoblox_username
  infoblox_password     = var.infoblox_password
  infoblox_network      = "10.0.0.0/24"
  infoblox_network_view = "default"
  create_dns_record     = true
  
  domain                = "example.com"
  subnet_mask           = "24"
  default_gateway       = "10.0.0.1"
  dns_servers           = ["10.0.0.2", "10.0.0.3"]
  
  # Extensible attributes for Infoblox
  infoblox_extensible_attributes = {
    "Owner"     = "DevOps Team"
    "Purpose"   = "Application Server"
    "Tenant"    = "Finance Department"
  }
}
```

### VM with Datastore Selection Logic

```hcl
module "storage_optimized_vm" {
  source = "./vsphere-vm"
  
  vsphere_server        = "vcenter.example.com"
  datacenter_id         = "DC01"
  cluster_id            = "Cluster01"
  template_id           = "rhel8-template"
  vm_name               = "db-server-01"
  os_family             = "linux"
  network_id            = "VM Network"
  
  # Datastore selection
  datastore_filter_regex = "SSD-[A-Z]+"  # Only use SSD datastores
  
  # Multi-disk configuration optimized for database
  root_disk_size_gb     = 50
  additional_disks      = [
    {
      label     = "data"
      size_gb   = 500
      thin_provisioned = false
    },
    {
      label     = "logs"
      size_gb   = 200
      thin_provisioned = true
    },
    {
      label     = "temp"
      size_gb   = 100
      thin_provisioned = true
    }
  ]
}
```

## Resource Selection Logic

### Datastore Selection

The module implements intelligent datastore selection using the following logic:

1. If `datastore_id` is specified, it is used directly
2. If `datastore_cluster_id` is specified, it is used and the vSphere DRS will handle disk placement
3. Otherwise, available datastores are filtered using `datastore_filter_regex` and sorted by free space
4. The datastore with the most free space is selected automatically

### Network Configuration

IP configuration can be handled in several ways:

1. DHCP (default) - No static IP configuration needed
2. Static IP - Specify `use_static_ip = true` and provide IP details
3. Infoblox IPAM:
   - Dynamic allocation - Enable Infoblox and specify the network
   - Reserved IP - Enable Infoblox and specify a specific IP to reserve

## Infoblox IPAM Integration

The module integrates with Infoblox for IP address management (IPAM) and DNS services:

### Features

- **Dynamic IP Allocation**: Automatically allocate the next available IP from a network
- **IP Reservation**: Reserve specific IPs when needed
- **DNS Records**: Create A and PTR records automatically
- **Extensible Attributes**: Add custom metadata to Infoblox records
- **IP Release**: Automatically release IPs when VMs are destroyed

### Configuration

1. Enable Infoblox integration:

```hcl
use_infoblox          = true
infoblox_grid_host    = "infoblox.example.com"
infoblox_username     = "apiuser"
infoblox_password     = "apipassword"
infoblox_network      = "10.0.0.0/24"
infoblox_network_view = "default"
```

2. For dynamic allocation, no additional configuration is needed

3. For reserved IPs:

```hcl
infoblox_reserve_ip   = true
infoblox_reserved_ip  = "10.0.0.50"
```

### IP Release Process

When a VM is destroyed:

1. The module identifies the allocated IP address
2. The IP is released from Infoblox using the `release_infoblox_ip.sh` script
3. Associated DNS records (A and PTR) are removed

## Operating System Customization

The module handles OS-specific customization based on the `os_family` parameter:

### Linux Customization

- Hostname and domain configuration
- Network settings (IP, gateway, DNS)
- No additional customization to maintain simplicity

### Windows Customization

- Computer name and domain/workgroup configuration
- Administrator password and auto-logon options
- Network settings (IP, gateway, DNS)
- Time zone and organization details
- Product key application if provided
- First boot commands via `windows_run_once_command_list`

## Required Permissions

### vSphere Permissions

- Virtual machine.Inventory.Create
- Virtual machine.Configuration.AddNewDisk
- Virtual machine.Configuration.AddExistingDisk
- Virtual machine.Configuration.AddRemoveDevice
- Virtual machine.Configuration.AdvancedConfig
- Virtual machine.Configuration.Annotation
- Virtual machine.Configuration.CPUCount
- Virtual machine.Configuration.Memory
- Virtual machine.Configuration.Settings
- Virtual machine.Provisioning.DeployTemplate
- Virtual machine.Provisioning.Customize
- Resource.AssignVMToPool
- Datastore.AllocateSpace
- Network.Assign

### Infoblox Permissions

The Infoblox API user requires the following permissions:

- IP address management (read and write)
- DNS record management (read and write)
- Network and network view access
- Extensible attributes access

## Module Maintenance

### Version Compatibility

| Module Version | vSphere Provider | Infoblox Provider | Terraform  |
|----------------|------------------|-------------------|------------|
| v1.0.0         | >= 2.0.0         | >= 2.0.0          | >= 1.0.0   |

### Troubleshooting

- **IP Allocation Failed**: Check Infoblox network availability and permissions
- **Datastore Selection Failed**: Verify datastore filter regex and available space
- **Customization Failed**: Ensure template is properly prepared for customization
- **DNS Record Creation Failed**: Verify DNS view permissions in Infoblox

## Contributing

Contributions to improve the module are welcome. Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a new Pull Request

## License

MIT

## Authors

DevOps Team