# Terraform vSphere VM Module for Cluster-Based Tenancy

This module enables deployment of virtual machines in a vSphere environment with tenant-specific clusters. It automatically selects appropriate datastores and networks based on the tenant cluster and supports multiple operating system options.

## Features

- **Cluster-based tenancy**: Each tenant has their own dedicated vSphere cluster
- **Smart resource selection**: Auto-selects datastores with most free space within the tenant's cluster
- **Multiple OS options**: Deploy RHEL, Ubuntu, or Windows with a simple parameter
- **Customizable VM specifications**: Configure CPU, memory, disk size, and more
- **Template-based deployment**: Clone from templates with proper customization options
- **Scalable**: Deploy single or multiple VMs with consistent naming

## Usage

```hcl
module "tenant_vms" {
  source = "./modules/vsphere-vm"
  
  # vSphere connection details
  vsphere_server   = "vcenter.example.com"
  vsphere_username = var.vsphere_user
  vsphere_password = var.vsphere_password
  
  # Deployment configuration 
  datacenter     = "Main-DC"
  tenant_cluster = "tenantA-cluster"  # The cluster is tenant-specific
  
  # VM details
  vm_name_prefix   = "webapp"
  vm_count         = 2
  operating_system = "rhel8"   # Choose from rhel7, rhel8, rhel9, ubuntu18, ubuntu20, ubuntu22, windows2016, windows2019, windows2022
  
  # Hardware specifications
  cpu            = 4
  memory         = 8192
  disk_size      = 100
  
  # Optional datastore selection
  datastore_regex = "^ds-ssd-.*$"  # Optional: select SSD datastores
  
  # Optional network selection
  network_name = "VM-Network-Prod"  # Optional: specify network
  
  # Optional settings for Windows VMs
  admin_password = var.windows_password # Only needed for Windows VMs
  
  # Optional networking
  ipv4_network_address = "192.168.10.0/24" # Optional static IP addressing
  ipv4_gateway         = "192.168.10.1"
  dns_servers          = ["8.8.8.8", "8.8.4.4"]
}
```

## Prerequisites

Before using this module, you need to set up the vSphere environment with:

1. **Cluster-Based Tenancy**: Each tenant should have their own dedicated vSphere cluster
2. **Folder Structure**: Create `/Tenants/{tenant_name}` folders for VM organization (optional)
3. **Template Preparation**: VM templates for each supported OS

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

1. **Cluster**: Uses the specified tenant cluster which serves as the tenant boundary
2. **Datastore**: 
   - If `datastore_regex` is provided, selects datastores matching that pattern
   - Otherwise, selects the datastore with the most free space in the cluster
3. **Network**:
   - If `network_name` is provided, uses that specific network
   - Otherwise, defaults to "VM Network"
4. **Resource Pool**:
   - If `resource_pool` is specified, uses that resource pool within the tenant cluster
   - Otherwise, uses the cluster's root resource pool
5. **Folder**:
   - If `folder` is specified, uses that folder path
   - Otherwise, places VMs in `/Tenants/{tenant_name}` folders

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
| tenant_cluster | vSphere cluster for tenant | string | - | yes |
| vm_name_prefix | Prefix for VM names | string | - | yes |
| vm_count | Number of VMs to create | number | 1 | no |
| operating_system | OS to deploy (see supported list) | string | "rhel8" | no |
| folder | VM folder | string | "/Tenants/{tenant_name}" | no |
| cpu | Number of vCPUs | number | 2 | no |
| memory | Memory in MB | number | 4096 | no |
| disk_size | Disk size in GB | number | 40 | no |
| datastore_regex | Pattern to select datastores | string | "" | no |
| network_name | Network to use | string | "VM Network" | no |
| ipv4_network_address | CIDR for static IPs | string | "" | no |
| ipv4_gateway | Default gateway | string | "" | no |
| dns_servers | List of DNS servers | list(string) | [] | no |
| admin_password | Windows admin password | string | "" | no |
| enable_disk_uuid | Enable disk UUID (for K8s) | bool | false | no |
| resource_pool | Resource pool within cluster | string | "" | no |

## Outputs

| Name | Description |
|------|-------------|
| vm_ids | IDs of created VMs |
| vm_names | Names of created VMs |
| vm_ips | IP addresses of created VMs |
| tenant_cluster | Tenant cluster used for deployment |
| datastore | Datastore used |
| network | Network used |
| operating_system | OS deployed |

## Cluster-Based Tenancy vs Tag-Based Tenancy

This module uses **cluster-based tenancy** which offers several advantages over tag-based approaches:

1. **Natural vSphere Organization**: Aligns with vSphere's organizational structure
2. **Simpler Resource Isolation**: Physical and logical separation at the cluster level
3. **Performance Isolation**: Dedicated resources per tenant
4. **Simplified Permission Model**: Permissions can be set at the cluster level
5. **Easier Capacity Planning**: Each tenant has their own resource pool

## Notes

- The module extracts the tenant name from the cluster name for folder organization
- For Windows VMs, you must provide the `admin_password` variable
- If static IP addressing is desired, provide the `ipv4_network_address` in CIDR notation (e.g., "192.168.1.0/24")
- The module will assign IPs sequentially starting from .10 in that subnet