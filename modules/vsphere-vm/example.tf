module "web_servers" {
  source = "./modules/vsphere-vm"
  
  # vSphere connection
  vsphere_server   = var.vsphere_server
  vsphere_username = var.vsphere_user
  vsphere_password = var.vsphere_password
  
  # Tenant and deployment information
  datacenter       = "Main-DC"
  cluster          = "Production"
  tenant_name      = "tenant-a"
  
  # VM specifications
  vm_name_prefix   = "web"
  vm_count         = 3
  operating_system = "rhel8"
  
  # Hardware
  cpu              = 4
  memory           = 8192
  disk_size        = 80
  
  # Networking (optional)
  ipv4_network_address = "10.10.1.0/24"
  ipv4_gateway         = "10.10.1.1"
  dns_servers          = ["10.10.0.10", "10.10.0.11"]
}