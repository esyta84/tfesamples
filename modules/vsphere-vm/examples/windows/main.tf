provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

module "windows_server" {
  source = "../../"
  
  # vSphere environment settings
  vsphere_server    = var.vsphere_server
  datacenter_id     = var.datacenter
  cluster_id        = var.cluster
  
  # VM identification and placement
  vm_name           = "win-server-01"
  folder_path       = "Production/Windows Servers"
  
  # VM template and OS settings
  template_id       = var.template_windows2019
  os_family         = "windows"
  
  # VM hardware configuration
  num_cpus          = 4
  memory_mb         = 8192
  
  # Network settings - static IP
  network_id        = var.network_name
  use_static_ip     = true
  static_ip_address = "10.0.1.100"
  subnet_mask       = "24"
  default_gateway   = "10.0.1.1"
  dns_servers       = ["10.0.1.2", "10.0.1.3"]
  dns_suffixes      = ["example.com", "corp.example.com"]
  
  # Windows specific customization
  domain                    = "example.com"
  windows_admin_password    = var.windows_admin_password
  domain_admin_user         = "administrator"
  domain_admin_password     = var.domain_admin_password
  windows_time_zone         = 85  # Eastern Standard Time
  windows_organization_name = "Example Corp"
  
  # Auto-logon and first boot commands
  windows_auto_logon        = true
  windows_auto_logon_count  = 1
  windows_run_once_command_list = [
    "powershell.exe -Command Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))",
    "powershell.exe -Command choco install -y 7zip notepadplusplus",
    "powershell.exe -Command Add-WindowsFeature Web-Server,Web-Mgmt-Tools"
  ]
  
  # Storage settings with multiple disks
  datastore_filter_regex = "SSD-*"  # Prefer SSD datastores
  root_disk_size_gb = 80
  root_disk_thin_provisioned = true
  
  additional_disks = [
    {
      label             = "data"
      size_gb           = 200
      thin_provisioned  = true
    },
    {
      label             = "logs"
      size_gb           = 100
      thin_provisioned  = true
    }
  ]
  
  # Advanced settings
  cpu_hot_add_enabled    = true
  memory_hot_add_enabled = true
  enable_efi             = true  # Use EFI firmware
  
  # VM notes
  annotation = "Windows server deployed via Terraform"
}