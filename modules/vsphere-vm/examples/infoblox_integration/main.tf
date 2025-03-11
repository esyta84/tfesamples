provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

module "app_server_with_ipam" {
  source = "../../"
  
  # vSphere environment settings
  vsphere_server    = var.vsphere_server
  datacenter_id     = var.datacenter
  cluster_id        = var.cluster
  
  # VM identification and placement
  vm_name           = "app-server-infoblox"
  folder_path       = "Production/Application Servers"
  
  # VM template and OS settings
  template_id       = var.template_rhel8
  os_family         = "linux"
  
  # VM hardware configuration
  num_cpus          = 4
  memory_mb         = 8192
  
  # Network settings
  network_id        = var.network_name
  
  # Infoblox IPAM integration for dynamic allocation
  use_infoblox          = true
  infoblox_grid_host    = var.infoblox_grid_host
  infoblox_username     = var.infoblox_username
  infoblox_password     = var.infoblox_password
  infoblox_network      = var.infoblox_network     # e.g. "10.0.0.0/24"
  infoblox_network_view = "default"
  create_dns_record     = true
  
  # Network configuration for the allocated IP
  use_static_ip         = true   # Use IP from Infoblox
  domain                = "example.com"
  subnet_mask           = "24"   # Corresponds to 255.255.255.0
  default_gateway       = var.default_gateway    # e.g. "10.0.0.1"
  dns_servers           = var.dns_servers        # e.g. ["10.0.0.2", "10.0.0.3"]
  dns_suffixes          = ["example.com", "corp.example.com"]
  
  # Extensible attributes for Infoblox records
  infoblox_extensible_attributes = {
    "Owner"       = "DevOps Team"
    "Environment" = "Production"
    "Application" = "ERP System"
    "Cost Center" = "CC-123456"
  }
  
  # Storage settings
  root_disk_size_gb = 50
  additional_disks  = [
    {
      label    = "data"
      size_gb  = 200
      thin_provisioned = true
    },
    {
      label    = "logs"
      size_gb  = 100
      thin_provisioned = true
    }
  ]
  
  # VM advanced configuration
  cpu_hot_add_enabled    = true
  memory_hot_add_enabled = true
  
  # VM notes
  annotation = "Application server with Infoblox IPAM integration"
}