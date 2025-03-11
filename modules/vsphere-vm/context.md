
## Generic vSphere VM Module

The module now provides a straightforward way to deploy VMs to any vSphere cluster with smart resource selection:

1. **Simplified Resource Selection**:
   - Automatically selects datastores with the most free space
   - Optional filtering via `datastore_regex` for specific storage types (SSD, HDD, etc.)
   - Support for datastore clusters with the `datastore_cluster` parameter

2. **Enhanced Storage Options**:
   - Added support for multiple disks with the `additional_disks` parameter
   - Customizable disk provisioning (thin/thick) and configuration

3. **Flexible VM Configuration**:
   - Multiple operating system support (RHEL, Ubuntu, Windows)
   - OS-specific customization 
   - Resource pool support
   - VM folder organization

4. **Network Configuration**:
   - Simplified network selection
   - Static IP assignment with CIDR support
   - DNS configuration

## Usage Example

Here's a simplified example showing how to deploy RHEL 8 web servers:

```hcl
module "web_servers" {
  source = "./modules/vsphere-vm"
  
  # vSphere connection
  vsphere_server   = var.vsphere_server
  vsphere_username = var.vsphere_user
  vsphere_password = var.vsphere_password
  
  # Deployment location
  datacenter     = "Main-DC"
  cluster        = "Production-Cluster"
  folder         = "WebServers"
  
  # VM details
  vm_name_prefix   = "web"
  vm_count         = 3
  operating_system = "rhel8"
  
  # Storage preferences - filter for SSD datastores
  datastore_regex = "^ssd-.*$"
  
  # Network configuration
  network_name          = "Production-Web-Network"
  ipv4_network_address  = "10.10.1.0/24"
  ipv4_gateway          = "10.10.1.1"
  dns_servers           = ["10.10.0.10", "10.10.0.11"]
  
  # Hardware specifications
  cpu              = 4
  memory           = 8192
  disk_size        = 80
}
```

## Advanced Features

1. **Database VMs with Multiple Disks**:
   ```hcl
   additional_disks = [
     {
       size             = 500
       thin_provisioned = false
       eagerly_scrub    = true
       unit_number      = 1
       label            = "db-data"
     },
     {
       size             = 200
       thin_provisioned = false
       eagerly_scrub    = true
       unit_number      = 2
       label            = "db-log"
     }
   ]
   ```

2. **Windows VMs with Proper Customization**:
   ```hcl
   operating_system = "windows2019"
   admin_password   = var.windows_password
   ```

3. **Kubernetes-Ready VMs**:
   ```hcl
   enable_disk_uuid = true  # Required for Kubernetes
   ```

4. **Resource Pool Support**:
   ```hcl
   resource_pool = "K8s-Platform"  # Use specific resource pool
   ```

The module provides comprehensive documentation in the README to help users understand all available options and best practices for deployment. It's been designed to be flexible enough for a wide range of use cases while maintaining ease of use.