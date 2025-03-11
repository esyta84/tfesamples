# Terraform vSphere VM Module

This module enables deployment of virtual machines in vSphere clusters with automatic resource selection. It supports multiple operating systems and provides extensive customization options.

## Features

- **Smart resource selection**: Automatically selects datastores with the most free space
- **Multiple OS options**: Deploy RHEL, Ubuntu, or Windows with a simple parameter
- **Customizable VM specifications**: Configure CPU, memory, disk size, and more
- **Template-based deployment**: Clone from templates with proper customization options
- **Multi-disk support**: Add additional disks with custom configurations
- **Scalable**: Deploy single or multiple VMs with consistent naming
- **Network customization**: Static or dynamic IP assignment

## Usage

```hcl
module "web_servers" {
  source = "./modules/vsphere-vm"
  
  # vSphere connection details
  vsphere_server   = "vcenter.example.com"
  vsphere_username = var.vsphere_user
  vsphere_password = var.vsphere_password
  
  # Deployment configuration 
  datacenter = "Main-DC"
  cluster    = "Production-Cluster"
  folder     = "Web-Servers"
  
  # VM details
  vm_name_prefix   = "web"
  vm_count         = 3
  operating_system = "rhel8"   # Choose from rhel7, rhel8, rhel9, ubuntu18, ubuntu20, ubuntu22, windows2016, windows2019, windows2022
  
  # Hardware specifications
  cpu       = 4
  memory    = 8192
  disk_size = 100
  
  # Additional disks
  additional_disks = [
    {
      size             = 200
      thin_provisioned = true
      eagerly_scrub    = false
      unit_number      = 1
      label            = "data-disk"
    }
  ]
  
  # Storage options
  datastore_regex = "^ssd-.*$"  # Optional: select SSD datastores
  
  # Network configuration
  network_name          = "Production-Network"
  ipv4_network_address  = "192.168.10.0/24"  # Optional: static IP addressing
  ipv4_gateway          = "192.168.10.1"
  dns_servers           = ["8.8.8.8", "8.8.4.4"]
  
  # Windows-specific settings (only needed for Windows VMs)
  admin_password = var.windows_password
}
```

## Prerequisites

Before using this module, you need to prepare your vSphere environment:

1. **Templates**: Prepare VM templates for each supported OS
2. **Resource Pools**: (Optional) Create resource pools for workload segregation
3. **Folders**: (Optional) Create VM folders for organization
4. **Networks**: Configure appropriate networks

## Operating System Support

The module supports the following operating systems:

| Parameter | Description | Template Name |
|-----------|-------------|---------------|
| `rhel7` | Red Hat Enterprise Linux 7 | rhel7-template |
| `rhel8` | Red Hat Enterprise Linux 8 | rhel8-template |
| `rhel9` | Red Hat Enterprise Linux 9 | rhel9-template |
| `ubuntu18` | Ubuntu 18.04 LTS | ubuntu18.04-template |
| `ubuntu20` | Ubuntu 20.04 LTS | ubuntu20.04-template |
| `ubuntu22` | Ubuntu 22.04 LTS | ubuntu22.04-template |
| `windows2016` | Windows Server 2016 | windows2016-template |
| `windows2019` | Windows Server 2019 | windows2019-template |
| `windows2022` | Windows Server 2022 | windows2022-template |

You can customize the template names in the module's `os_templates` local variable if needed.

## Resource Selection

The module selects resources as follows:

1. **Datastore**: 
   - If `datastore_cluster` is provided, uses that datastore cluster
   - If `datastore_regex` is provided, selects datastores matching that pattern
   - Otherwise, selects the datastore with the most free space in the cluster
2. **Network**:
   - If `network_name` is provided, uses that specific network
   - Otherwise, defaults to "VM Network"
3. **Resource Pool**:
   - If `resource_pool` is specified, uses that resource pool within the cluster
   - Otherwise, uses the cluster's root resource pool
4. **Folder**:
   - Uses the specified folder for VM placement

## Guest Customization

The module handles guest customization differently for Linux and Windows VMs:

- **Linux VMs**: Sets hostname and domain
- **Windows VMs**: Sets computer name, administrator password, and basic Windows settings

For static IP addressing, provide the `ipv4_network_address` (CIDR notation) and `ipv4_gateway`.

## Requirements

- Terraform >= 0.14.0
- vSphere provider >= 2.0.0
- vSphere environment with clusters, resource pools, and templates

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vsphere_server | vSphere server address | string | - | yes |
| vsphere_username | vSphere username | string | - | yes |
| vsphere_password | vSphere password | string | - | yes |
| datacenter | vSphere datacenter name | string | - | yes |
| cluster | vSphere cluster name | string | - | yes |
| vm_name_prefix | Prefix for VM names | string | - | yes |
| vm_count | Number of VMs to create | number | 1 | no |
| operating_system | OS to deploy (see supported list) | string | "rhel8" | no |
| folder | VM folder | string | "" | no |
| cpu | Number of vCPUs | number | 2 | no |
| memory | Memory in MB | number | 4096 | no |
| disk_size | Disk size in GB | number | 40 | no |
| additional_disks | List of additional disk specifications | list(object) | [] | no |
| datastore_regex | Pattern to select datastores | string | "" | no |
| datastore_cluster | Datastore cluster to use | string | "" | no |
| network_name | Network to use | string | "VM Network" | no |
| ipv4_network_address | CIDR for static IPs | string | "" | no |
| ipv4_gateway | Default gateway | string | "" | no |
| dns_servers | List of DNS servers | list(string) | [] | no |
| admin_password | Windows admin password | string | "" | no |
| enable_disk_uuid | Enable disk UUID (for K8s) | bool | false | no |
| resource_pool | Resource pool within cluster | string | "" | no |
| template_folder | Folder containing templates | string | "Templates" | no |

## Outputs

| Name | Description |
|------|-------------|
| vm_ids | IDs of created VMs |
| vm_names | Names of created VMs |
| vm_ips | IP addresses of created VMs |
| cluster | Cluster used for deployment |
| datastore | Datastore or datastore cluster used |
| network | Network used |
| operating_system | OS deployed |

## Advanced Features

### 1. Multiple Disks

You can add additional disks to your VMs using the `additional_disks` variable:

```hcl
additional_disks = [
  {
    size             = 100
    thin_provisioned = true
    eagerly_scrub    = false
    unit_number      = 1
    label            = "data-disk"
  },
  {
    size             = 500
    thin_provisioned = false
    eagerly_scrub    = true
    unit_number      = 2
    label            = "db-disk"  
  }
]
```

### 2. Storage Selection

Multiple options for selecting storage:

- Use `datastore_regex` to filter by name pattern (e.g., `"^ssd-.*$"` for SSD datastores)
- Use `datastore_cluster` to specify a datastore cluster
- Omit both to automatically select the datastore with the most free space

### 3. VM Customization

For Windows VMs:

```hcl
# Windows VM specific configuration
admin_password = var.windows_password
```

For Linux VMs with static IP:

```hcl
# Static IP configuration
ipv4_network_address = "10.0.0.0/24"
ipv4_gateway         = "10.0.0.1"
dns_servers          = ["10.0.0.10", "10.0.0.11"]
```

### 4. Kubernetes Support

For VMs that will be used with Kubernetes, enable disk UUID:

```hcl
enable_disk_uuid = true
```

## Notes

- For Windows VMs, you must provide the `admin_password` variable
- If static IP addressing is desired, provide the `ipv4_network_address` in CIDR notation (e.g., "192.168.1.0/24")
- The module will assign IPs sequentially starting from .10 in that subnet
- Make sure the VM templates are properly prepared with VMware Tools installed