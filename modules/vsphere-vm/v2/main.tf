/**
 * # vSphere VM Module
 * 
 * A Terraform module for deploying VMs in vSphere clusters with automatic resource selection.
 * Supports multiple operating systems and customizable VM configurations.
 */

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "vsphere_server" {
  description = "vSphere server address"
  type        = string
}

variable "vsphere_username" {
  description = "vSphere username for API access"
  type        = string
  sensitive   = true
}

variable "vsphere_password" {
  description = "vSphere password for API access"
  type        = string
  sensitive   = true
}

variable "datacenter" {
  description = "vSphere datacenter name where VMs will be deployed"
  type        = string
}

variable "cluster" {
  description = "vSphere cluster name where VMs will be deployed"
  type        = string
}

variable "vm_name_prefix" {
  description = "Prefix for the VM name"
  type        = string
  default     = ""
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 1
  validation {
    condition     = var.vm_count > 0
    error_message = "VM count must be greater than 0."
  }
}

variable "folder" {
  description = "VM folder"
  type        = string
  default     = ""
}

variable "operating_system" {
  description = "Operating system to deploy (rhel7, rhel8, rhel9, ubuntu18, ubuntu20, ubuntu22, windows2016, windows2019, windows2022)"
  type        = string
  default     = "rhel8"
  validation {
    condition     = contains(["rhel7", "rhel8", "rhel9", "ubuntu18", "ubuntu20", "ubuntu22", "windows2016", "windows2019", "windows2022"], var.operating_system)
    error_message = "Operating system must be one of: rhel7, rhel8, rhel9, ubuntu18, ubuntu20, ubuntu22, windows2016, windows2019, windows2022."
  }
}

variable "cpu" {
  description = "Number of vCPUs"
  type        = number
  default     = 2
  validation {
    condition     = var.cpu >= 1
    error_message = "CPU count must be at least 1."
  }
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 4096
  validation {
    condition     = var.memory >= 1024
    error_message = "Memory must be at least 1024 MB."
  }
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 40
  validation {
    condition     = var.disk_size >= 10
    error_message = "Disk size must be at least 10 GB."
  }
}

variable "annotation" {
  description = "VM annotation"
  type        = string
  default     = ""
}

variable "datastore_regex" {
  description = "Regular expression to match datastores. Default uses the datastore with most free space."
  type        = string
  default     = ""
}

variable "datastore_cluster" {
  description = "Datastore cluster to use, if applicable"
  type        = string
  default     = ""
}

variable "network_name" {
  description = "Network name to use (if not provided, will use the first network found in cluster)"
  type        = string
  default     = ""
}

variable "enable_disk_uuid" {
  description = "Enable disk UUID for the VM (required for Kubernetes)"
  type        = bool
  default     = false
}

variable "custom_attributes" {
  description = "Custom attributes to apply to the VM"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to the VM (requires vSphere tag categories to exist)"
  type        = map(string)
  default     = {}
}

variable "wait_for_guest_ip_timeout" {
  description = "Timeout for waiting for guest IP"
  type        = number
  default     = 300
}

variable "domain" {
  description = "Domain for VMs (used in guest customization)"
  type        = string
  default     = "local.domain"
}

variable "ipv4_network_address" {
  description = "IPv4 network address for static IP configuration (e.g. 192.168.1.0/24)"
  type        = string
  default     = ""
}

variable "ipv4_gateway" {
  description = "IPv4 gateway for static IP configuration"
  type        = string
  default     = ""
}

variable "dns_servers" {
  description = "List of DNS servers"
  type        = list(string)
  default     = []
}

variable "admin_password" {
  description = "Administrator password for Windows VMs"
  type        = string
  default     = ""
  sensitive   = true
}

variable "resource_pool" {
  description = "Resource pool where VM will be deployed (defaults to cluster root resource pool)"
  type        = string
  default     = ""
}

variable "additional_disks" {
  description = "List of additional disks to add to the VM"
  type = list(object({
    size            = number
    thin_provisioned = bool
    eagerly_scrub    = bool
    unit_number      = number
    label           = string
  }))
  default = []
}

variable "template_folder" {
  description = "Folder containing VM templates"
  type        = string
  default     = "Templates"
}

# -----------------------------------------------------------------------------
# Data Sources & Locals
# -----------------------------------------------------------------------------

# Common variables that will be used for resource selection
locals {
  # OS templates mapping
  os_templates = {
    "rhel7"       = "rhel7-template"
    "rhel8"       = "rhel8-template"
    "rhel9"       = "rhel9-template"
    "ubuntu18"    = "ubuntu18.04-template"
    "ubuntu20"    = "ubuntu20.04-template"
    "ubuntu22"    = "ubuntu22.04-template"
    "windows2016" = "windows2016-template"
    "windows2019" = "windows2019-template"
    "windows2022" = "windows2022-template"
  }
  
  selected_template = local.os_templates[var.operating_system]
  is_windows = startswith(var.operating_system, "windows")
  is_linux = !local.is_windows
  
  # Determine resource pool path
  resource_pool_path = var.resource_pool != "" ? "${var.cluster}/${var.resource_pool}" : var.cluster
  
  # Template path
  template_path = "${var.template_folder}/${local.selected_template}"
}

# vSphere objects
data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = local.resource_pool_path
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Datastore selection - either specific cluster, regex match, or most free space
data "vsphere_datastore_cluster" "datastore_cluster" {
  count         = var.datastore_cluster != "" ? 1 : 0
  name          = var.datastore_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  count         = var.datastore_cluster == "" ? 1 : 0
  datacenter_id = data.vsphere_datacenter.dc.id
  
  # If regex provided, use it to filter
  name_regex    = var.datastore_regex != "" ? var.datastore_regex : null
  
  # Select datastore with most free space (relative to its size)
  sort {
    # Sort on free space percentage (descending)
    attribute = "free_space_percent"
    order     = "desc"
  }
}

# Network selection
data "vsphere_network" "network" {
  name          = var.network_name != "" ? var.network_name : "VM Network"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Get OS template
data "vsphere_virtual_machine" "template" {
  name          = local.template_path
  datacenter_id = data.vsphere_datacenter.dc.id
}

# -----------------------------------------------------------------------------
# Resources
# -----------------------------------------------------------------------------

resource "vsphere_virtual_machine" "vm" {
  count = var.vm_count

  name             = var.vm_count > 1 ? "${var.vm_name_prefix}-${count.index + 1}" : var.vm_name_prefix
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = var.datastore_cluster != "" ? data.vsphere_datastore_cluster.datastore_cluster[0].id : data.vsphere_datastore.datastore[0].id
  folder           = var.folder
  
  num_cpus         = var.cpu
  memory           = var.memory
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  scsi_type        = data.vsphere_virtual_machine.template.scsi_type
  firmware         = data.vsphere_virtual_machine.template.firmware
  
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }
  
  disk {
    label            = "disk0"
    size             = var.disk_size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks[0].eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks[0].thin_provisioned
  }
  
  # Add additional disks if specified
  dynamic "disk" {
    for_each = var.additional_disks
    content {
      label            = disk.value.label
      size             = disk.value.size
      unit_number      = disk.value.unit_number
      thin_provisioned = disk.value.thin_provisioned
      eagerly_scrub    = disk.value.eagerly_scrub
    }
  }
  
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    
    customize {
      dynamic "linux_options" {
        for_each = local.is_linux ? [1] : []
        content {
          host_name = var.vm_count > 1 ? "${var.vm_name_prefix}-${count.index + 1}" : var.vm_name_prefix
          domain    = var.domain
        }
      }
      
      dynamic "windows_options" {
        for_each = local.is_windows ? [1] : []
        content {
          computer_name  = var.vm_count > 1 ? "${var.vm_name_prefix}-${count.index + 1}" : var.vm_name_prefix
          admin_password = var.admin_password
          # Windows customization options
          auto_logon      = false
          time_zone       = 85 # Eastern Standard Time
          workgroup       = "WORKGROUP"
          join_domain     = ""
          domain_admin_user = ""
          domain_admin_password = ""
          product_key     = ""
          full_name       = "Administrator"
          organization_name = "Organization"
          run_once_command_list = []
        }
      }
      
      dynamic "network_interface" {
        for_each = var.ipv4_network_address != "" ? [1] : []
        content {
          ipv4_address = cidrhost(var.ipv4_network_address, count.index + 10)
          ipv4_netmask = split("/", var.ipv4_network_address)[1]
        }
      }
      
      dns_server_list = var.dns_servers
      ipv4_gateway    = var.ipv4_gateway
    }
  }
  
  annotation = var.annotation != "" ? var.annotation : "Managed by Terraform. Cluster: ${var.cluster}, OS: ${var.operating_system}"
  
  # For Kubernetes support
  enable_disk_uuid = var.enable_disk_uuid
  
  # Custom attributes
  dynamic "custom_attribute" {
    for_each = var.custom_attributes
    content {
      key   = custom_attribute.key
      value = custom_attribute.value
    }
  }
  
  wait_for_guest_ip_timeout = var.wait_for_guest_ip_timeout
  
  lifecycle {
    ignore_changes = [
      annotation,
      clone[0].template_uuid,
    ]
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "vm_ids" {
  description = "The IDs of the created VMs"
  value       = vsphere_virtual_machine.vm[*].id
}

output "vm_names" {
  description = "The names of the created VMs"
  value       = vsphere_virtual_machine.vm[*].name
}

output "vm_ips" {
  description = "The IP addresses of the created VMs"
  value       = vsphere_virtual_machine.vm[*].default_ip_address
}

output "cluster" {
  description = "The cluster used for VM deployment"
  value       = var.cluster
}

output "datastore" {
  description = "The datastore used for VM deployment"
  value       = var.datastore_cluster != "" ? var.datastore_cluster : data.vsphere_datastore.datastore[0].name
}

output "network" {
  description = "The network used for VM deployment"
  value       = data.vsphere_network.network.name
}

output "operating_system" {
  description = "The operating system deployed"
  value       = var.operating_system
}