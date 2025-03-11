variable "vsphere_server" {
  description = "vSphere server FQDN or IP address"
  type        = string
}

# VM Identification
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  validation {
    condition     = length(var.vm_name) > 2 && length(var.vm_name) <= 60
    error_message = "VM name must be between 3 and 60 characters."
  }
}

# vSphere environment settings
variable "datacenter_id" {
  description = "vSphere datacenter ID where the VM will be deployed"
  type        = string
}

variable "cluster_id" {
  description = "vSphere cluster ID where the VM will be deployed"
  type        = string
}

variable "resource_pool_id" {
  description = "vSphere resource pool ID. If empty, the cluster root resource pool will be used"
  type        = string
  default     = ""
}

variable "folder_path" {
  description = "VM folder path where the VM will be placed"
  type        = string
  default     = ""
}

# Datastore selection
variable "datastore_id" {
  description = "Specific datastore ID to use for VM. If empty, the module will select the datastore with the most free space"
  type        = string
  default     = ""
}

variable "datastore_cluster_id" {
  description = "Datastore cluster ID to use for VM. Takes precedence over datastore_id if both are specified"
  type        = string
  default     = ""
}

variable "datastore_filter_regex" {
  description = "Regular expression to filter available datastores. Only used if datastore_id and datastore_cluster_id are empty"
  type        = string
  default     = ".*"
}

# VM Hardware configuration
variable "num_cpus" {
  description = "Number of vCPUs for the VM"
  type        = number
  default     = 2
  validation {
    condition     = var.num_cpus > 0
    error_message = "Number of CPUs must be greater than 0."
  }
}

variable "memory_mb" {
  description = "Memory size in MB for the VM"
  type        = number
  default     = 4096
  validation {
    condition     = var.memory_mb >= 1024
    error_message = "Memory must be at least 1024 MB (1 GB)."
  }
}

variable "cpu_hot_add_enabled" {
  description = "Enable CPU hot add"
  type        = bool
  default     = false
}

variable "memory_hot_add_enabled" {
  description = "Enable memory hot add"
  type        = bool
  default     = false
}

variable "enable_efi" {
  description = "Enable EFI firmware instead of BIOS"
  type        = bool
  default     = false
}

# VM template and OS settings
variable "template_id" {
  description = "ID of the VM template to clone"
  type        = string
}

variable "os_family" {
  description = "OS family (linux, windows)"
  type        = string
  validation {
    condition     = contains(["linux", "windows", "rhel", "ubuntu"], lower(var.os_family))
    error_message = "OS family must be one of: linux, windows, rhel, ubuntu."
  }
}

# Disk configuration
variable "root_disk_size_gb" {
  description = "Size of the root disk in GB. If 0, the template's disk size will be used"
  type        = number
  default     = 0
}

variable "root_disk_thin_provisioned" {
  description = "Enable thin provisioning for the root disk"
  type        = bool
  default     = true
}

variable "root_disk_eagerly_scrub" {
  description = "Enable eager scrubbing for the root disk (not compatible with thin provisioning)"
  type        = bool
  default     = false
}

variable "additional_disks" {
  description = "List of additional disks to add to the VM"
  type = list(object({
    label            = string
    size_gb          = number
    thin_provisioned = optional(bool, true)
    eagerly_scrub    = optional(bool, false)
    unit_number      = optional(number)
    datastore_id     = optional(string)
  }))
  default = []
}

# Network configuration
variable "network_id" {
  description = "ID of the network to connect to the VM"
  type        = string
}

variable "use_static_ip" {
  description = "Use static IP address configuration instead of DHCP"
  type        = bool
  default     = false
}

variable "static_ip_address" {
  description = "Static IP address to use for the VM (required if use_static_ip is true and not using Infoblox)"
  type        = string
  default     = ""
}

variable "subnet_mask" {
  description = "Subnet mask to use for static IP (in CIDR notation for infoblox, e.g., 24 for 255.255.255.0)"
  type        = string
  default     = ""
}

variable "default_gateway" {
  description = "Default gateway for the VM"
  type        = string
  default     = ""
}

variable "dns_servers" {
  description = "List of DNS servers for the VM"
  type        = list(string)
  default     = []
}

variable "dns_suffixes" {
  description = "List of DNS suffixes for the VM"
  type        = list(string)
  default     = []
}

variable "mac_address" {
  description = "MAC address to assign to the network interface (optional)"
  type        = string
  default     = ""
}

variable "domain" {
  description = "Domain name for the VM"
  type        = string
  default     = ""
}

# Windows-specific settings
variable "windows_admin_password" {
  description = "Administrator password for Windows VM"
  type        = string
  default     = ""
  sensitive   = true
}

variable "windows_workgroup" {
  description = "Workgroup for Windows VM (if not joining a domain)"
  type        = string
  default     = ""
}

variable "domain_admin_user" {
  description = "Domain admin username for joining a domain (Windows only)"
  type        = string
  default     = ""
}

variable "domain_admin_password" {
  description = "Domain admin password for joining a domain (Windows only)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "windows_time_zone" {
  description = "Time zone for Windows VM"
  type        = number
  default     = 85 # Eastern Standard Time
}

variable "windows_product_key" {
  description = "Product key for Windows VM"
  type        = string
  default     = ""
  sensitive   = true
}

variable "windows_organization_name" {
  description = "Organization name for Windows VM"
  type        = string
  default     = "Organization"
}

variable "windows_auto_logon" {
  description = "Enable auto logon for Windows VM"
  type        = bool
  default     = false
}

variable "windows_auto_logon_count" {
  description = "Number of auto logons for Windows VM"
  type        = number
  default     = 1
}

variable "windows_run_once_command_list" {
  description = "List of commands to run during first logon for Windows VM"
  type        = list(string)
  default     = []
}

# vApp properties
variable "vapp_properties" {
  description = "Map of vApp properties to set on the VM"
  type        = map(string)
  default     = {}
}

# Wait timeouts
variable "wait_for_guest_net_timeout" {
  description = "Timeout for waiting for guest network to be available"
  type        = number
  default     = 5
}

variable "wait_for_guest_ip_timeout" {
  description = "Timeout for waiting for guest IP to be available"
  type        = number
  default     = 5
}

# Lifecycle management
variable "prevent_destroy" {
  description = "Prevent destruction of the VM"
  type        = bool
  default     = false
}

variable "prevent_update" {
  description = "Prevent updates to the VM (ignore_changes for all attributes)"
  type        = bool
  default     = false
}

variable "annotation" {
  description = "VM annotation/notes"
  type        = string
  default     = ""
}

# Infoblox IPAM integration
variable "use_infoblox" {
  description = "Use Infoblox for IP allocation"
  type        = bool
  default     = false
}

variable "infoblox_grid_host" {
  description = "Infoblox Grid host"
  type        = string
  default     = ""
}

variable "infoblox_username" {
  description = "Infoblox username"
  type        = string
  default     = ""
}

variable "infoblox_password" {
  description = "Infoblox password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "infoblox_network" {
  description = "Infoblox network to allocate IP from (e.g., 10.0.0.0/24)"
  type        = string
  default     = ""
}

variable "infoblox_network_view" {
  description = "Infoblox network view"
  type        = string
  default     = "default"
}

variable "infoblox_dns_view" {
  description = "Infoblox DNS view"
  type        = string
  default     = "default"
}

variable "infoblox_reserve_ip" {
  description = "Reserve specific IP address in Infoblox instead of dynamic allocation"
  type        = bool
  default     = false
}

variable "infoblox_reserved_ip" {
  description = "Specific IP address to reserve in Infoblox"
  type        = string
  default     = ""
}

variable "infoblox_extensible_attributes" {
  description = "Map of extensible attributes to set on the Infoblox record"
  type        = map(string)
  default     = {}
}

variable "infoblox_ttl" {
  description = "TTL for Infoblox DNS records"
  type        = number
  default     = 3600
}

variable "infoblox_tenant_id" {
  description = "Infoblox tenant ID for multi-tenant environments"
  type        = string
  default     = ""
}

variable "create_dns_record" {
  description = "Create DNS record in Infoblox"
  type        = bool
  default     = true
}