provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

provider "infoblox" {
  server     = var.infoblox_grid_host
  username   = var.infoblox_username
  password   = var.infoblox_password
  ssl_verify = false
}

module "database_server" {
  source = "../../"
  
  # vSphere environment settings
  vsphere_server    = var.vsphere_server
  datacenter_id     = var.datacenter
  cluster_id        = var.cluster
  resource_pool_id  = var.resource_pool_db  # DB-specific resource pool with reserved resources
  
  # VM identification and placement
  vm_name           = "db-server-01"
  folder_path       = "Production/Database Servers"
  
  # VM template and OS settings
  template_id       = var.template_rhel8
  os_family         = "linux"
  
  # VM hardware configuration
  num_cpus          = 8
  memory_mb         = 32768  # 32 GB
  
  # Network settings with Infoblox integration
  network_id        = var.network_name
  use_infoblox      = true
  infoblox_grid_host = var.infoblox_grid_host
  infoblox_username = var.infoblox_username
  infoblox_password = var.infoblox_password
  infoblox_network  = var.infoblox_network
  create_dns_record = true
  
  # Reserve a specific IP in Infoblox
  infoblox_reserve_ip = true
  infoblox_reserved_ip = "10.0.0.50"  # Reserved static IP for the database
  
  # Network configuration
  use_static_ip     = true
  domain            = "example.com"
  subnet_mask       = "24"
  default_gateway   = var.default_gateway
  dns_servers       = var.dns_servers
  dns_suffixes      = ["example.com"]
  
  # Infoblox metadata
  infoblox_extensible_attributes = {
    "Owner"       = "Database Team"
    "Environment" = "Production"
    "Application" = "PostgreSQL"
    "Backup"      = "Daily"
    "Criticality" = "High"
  }
  
  # Storage configuration optimized for database workloads
  datastore_filter_regex = "SSD-Enterprise-*"  # Only use enterprise SSD storage
  root_disk_size_gb      = 100
  root_disk_thin_provisioned = false  # Use thick provisioning for performance
  
  # Multi-disk configuration for database
  additional_disks = [
    {
      # Data files disk
      label             = "pgdata"
      size_gb           = 500
      thin_provisioned  = false  # Thick provisioned for performance
      eagerly_scrub     = true   # Pre-allocate and zero out for best performance
    },
    {
      # Transaction logs disk
      label             = "pglogs"
      size_gb           = 200
      thin_provisioned  = false
      eagerly_scrub     = true
    },
    {
      # Index disk
      label             = "pgindex"
      size_gb           = 300
      thin_provisioned  = false
      eagerly_scrub     = true
    },
    {
      # Temp/work disk
      label             = "pgtemp"
      size_gb           = 200
      thin_provisioned  = true  # Can use thin provisioning for temp space
    },
    {
      # Backup disk
      label             = "pgbackup"
      size_gb           = 1000
      thin_provisioned  = true  # Thin provisioning for backup space
    }
  ]
  
  # Advanced configuration
  cpu_hot_add_enabled    = true
  memory_hot_add_enabled = true
  
  # VM notes
  annotation = "PostgreSQL database server with optimized storage configuration"
  
  # Lifecycle management
  prevent_destroy = true  # Protect production database from accidental destruction
}