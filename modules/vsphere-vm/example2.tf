# Example usage of the vSphere VM Module

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

# Variables
variable "vsphere_user" {
  description = "vSphere user name"
  type        = string
  sensitive   = true
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "vSphere server address"
  type        = string
  default     = "vcenter.example.com"
}

variable "windows_password" {
  description = "Windows administrator password"
  type        = string
  sensitive   = true
  default     = ""
}

# Production Web Servers
module "web_servers" {
  source = "./modules/vsphere-vm"
  
  # vSphere connection
  vsphere_server   = var.vsphere_server
  vsphere_username = var.vsphere_user
  vsphere_password = var.vsphere_password
  
  # Deployment configuration
  datacenter     = "Main-DC"
  cluster        = "Production-Cluster"
  folder         = "WebServers"
  
  # VM configuration
  vm_name_prefix   = "web"
  vm_count         = 3
  operating_system = "rhel8"
  
  # Optional filtering for SSD datastores
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

# Database Servers with multiple disks and resource pool
module "database_servers" {
  source = "./modules/vsphere-vm"
  
  # vSphere connection
  vsphere_server   = var.vsphere_server
  vsphere_username = var.vsphere_user
  vsphere_password = var.vsphere_password
  
  # Deployment configuration
  datacenter     = "Main-DC"
  cluster        = "Production-Cluster"
  resource_pool  = "DB-Tier"
  folder         = "DatabaseServers"
  
  # VM configuration
  vm_name_prefix   = "db"
  vm_count         = 2
  operating_system = "ubuntu20"
  
  # Optional filtering for high-performance datastores
  datastore_regex = "^performance-.*$"
  
  # Network configuration
  network_name          = "Production-DB-Network"
  ipv4_network_address  = "10.10.2.0/24"
  ipv4_gateway          = "10.10.2.1"
  dns_servers           = ["10.10.0.10", "10.10.0.11"]
  
  # Hardware specifications
  cpu              = 8
  memory           = 32768
  disk_size        = 100
  
  # Additional disks for database storage
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
}

# Windows Application Servers
module "app_servers" {
  source = "./modules/vsphere-vm"
  
  # vSphere connection
  vsphere_server   = var.vsphere_server
  vsphere_username = var.vsphere_user
  vsphere_password = var.vsphere_password
  
  # Deployment configuration
  datacenter     = "Main-DC"
  cluster        = "Production-Cluster"
  folder         = "AppServers"
  
  # VM configuration
  vm_name_prefix   = "app"
  vm_count         = 2
  operating_system = "windows2019"
  
  # Windows-specific settings
  admin_password   = var.windows_password
  
  # Network configuration
  network_name          = "Production-App-Network"
  ipv4_network_address  = "10.10.3.0/24"
  ipv4_gateway          = "10.10.3.1"
  dns_servers           = ["10.10.0.10", "10.10.0.11"]
  
  # Hardware specifications
  cpu              = 4
  memory           = 16384
  disk_size        = 100
}

# Development Test VMs
module "dev_test_vms" {
  source = "./modules/vsphere-vm"
  
  # vSphere connection
  vsphere_server   = var.vsphere_server
  vsphere_username = var.vsphere_user
  vsphere_password = var.vsphere_password
  
  # Deployment configuration
  datacenter     = "Main-DC"
  cluster        = "Development-Cluster"
  folder         = "Development/TestVMs"
  
  # VM configuration
  vm_name_prefix   = "dev-test"
  vm_count         = 1
  operating_system = "windows2022"
  
  # Windows-specific settings
  admin_password   = var.windows_password
  
  # Use a specific isolated network
  network_name     = "Dev-Isolated-Network"
  
  # Hardware specifications
  cpu              = 2
  memory           = 4096
  disk_size        = 100
}

# Kubernetes Nodes
module "kubernetes_nodes" {
  source = "./modules/vsphere-vm"
  
  # vSphere connection
  vsphere_server   = var.vsphere_server
  vsphere_username = var.vsphere_user
  vsphere_password = var.vsphere_password
  
  # Deployment configuration
  datacenter     = "Main-DC"
  cluster        = "Production-Cluster"
  resource_pool  = "K8s-Platform"
  folder         = "Kubernetes/Nodes"
  
  # VM configuration
  vm_name_prefix   = "k8s-node"
  vm_count         = 3
  operating_system = "rhel9"
  
  # Enable disk UUID for Kubernetes
  enable_disk_uuid = true
  
  # Use datastore cluster instead of individual datastore
  datastore_cluster = "K8s-Storage-Cluster"
  
  # Network configuration
  network_name          = "K8s-Network"
  ipv4_network_address  = "10.10.4.0/24"
  ipv4_gateway          = "10.10.4.1"
  dns_servers           = ["10.10.0.10", "10.10.0.11"]
  
  # Hardware specifications
  cpu              = 8
  memory           = 16384
  disk_size        = 100
  
  # Additional disk for container storage
  additional_disks = [
    {
      size             = 200
      thin_provisioned = true
      eagerly_scrub    = false
      unit_number      = 1
      label            = "container-storage"
    }
  ]
}

# Outputs
output "web_server_ips" {
  description = "IP addresses of web servers"
  value       = module.web_servers.vm_ips
}

output "database_server_ips" {
  description = "IP addresses of database servers"
  value       = module.database_servers.vm_ips
}

output "app_server_ips" {
  description = "IP addresses of application servers"
  value       = module.app_servers.vm_ips
}

output "dev_vm_details" {
  description = "Details of development VM"
  value = {
    name      = module.dev_test_vms.vm_names[0]
    ip        = module.dev_test_vms.vm_ips[0]
    cluster   = module.dev_test_vms.cluster
    network   = module.dev_test_vms.network
    datastore = module.dev_test_vms.datastore
    os        = module.dev_test_vms.operating_system
  }
}

output "k8s_node_ips" {
  description = "IP addresses of Kubernetes nodes"
  value       = module.kubernetes_nodes.vm_ips
}