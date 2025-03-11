locals {
  # Normalize OS family based on input
  os_family = lower(var.os_family) == "linux" || lower(var.os_family) == "rhel" || lower(var.os_family) == "ubuntu" ? "linux" : "windows"
  
  # Datastore selection logic
  datastores = var.datastore_cluster_id != "" ? [] : [
    for ds in data.vsphere_datastore.datastores : {
      id         = ds.id
      name       = ds.name
      free_space = ds.free_space
    }
  ]
  
  # Sort datastores by free space (descending)
  sorted_datastores = length(local.datastores) > 0 ? sort(
    local.datastores,
    (a, b) => a.free_space > b.free_space ? -1 : 1
  ) : []
  
  # Select datastore with most free space or use specified datastore if provided
  selected_datastore_id = var.datastore_id != "" ? var.datastore_id : (
    var.datastore_cluster_id != "" ? var.datastore_cluster_id : (
      length(local.sorted_datastores) > 0 ? local.sorted_datastores[0].id : ""
    )
  )
  
  # Network configuration with Infoblox IP
  network_interface = {
    network_id     = var.network_id
    use_static_mac = var.mac_address != "" ? true : false
    mac_address    = var.mac_address
  }
  
  # Determine IP configuration based on Infoblox allocation
  ipv4_config = var.use_static_ip ? {
    ip_address = var.static_ip_address != "" ? var.static_ip_address : local.infoblox_allocated_ip
    netmask    = var.subnet_mask
    gateway    = var.default_gateway
  } : null
  
  # DNS configuration
  dns_config = {
    dns_server_list = var.dns_servers
    dns_suffix_list = var.dns_suffixes
  }
}

# Create VM
resource "vsphere_virtual_machine" "vm" {
  name                 = var.vm_name
  resource_pool_id     = var.resource_pool_id != "" ? var.resource_pool_id : data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id         = local.selected_datastore_id
  datastore_cluster_id = var.datastore_cluster_id
  folder               = var.folder_path
  
  num_cpus             = var.num_cpus
  memory               = var.memory_mb
  guest_id             = data.vsphere_virtual_machine.template.guest_id
  scsi_type            = data.vsphere_virtual_machine.template.scsi_type
  
  # Network interfaces
  network_interface {
    network_id   = local.network_interface.network_id
    use_static_mac = local.network_interface.use_static_mac
    mac_address  = local.network_interface.use_static_mac ? local.network_interface.mac_address : null
  }
  
  # Root disk
  disk {
    label            = "disk0"
    size             = var.root_disk_size_gb > 0 ? var.root_disk_size_gb : data.vsphere_virtual_machine.template.disks[0].size
    eagerly_scrub    = var.root_disk_eagerly_scrub
    thin_provisioned = var.root_disk_thin_provisioned
  }
  
  # Additional disks (from disk_config.tf)
  dynamic "disk" {
    for_each = var.additional_disks
    content {
      label             = disk.value.label
      size              = disk.value.size_gb
      eagerly_scrub     = lookup(disk.value, "eagerly_scrub", false)
      thin_provisioned  = lookup(disk.value, "thin_provisioned", true)
      unit_number       = lookup(disk.value, "unit_number", (disk.key + 1))
      datastore_id      = lookup(disk.value, "datastore_id", null)
    }
  }
  
  # Clone configuration
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    
    # OS-specific customization
    dynamic "customize" {
      for_each = local.os_family == "linux" ? [1] : []
      content {
        linux_options {
          host_name = var.vm_name
          domain    = var.domain
        }
        
        dynamic "network_interface" {
          for_each = local.ipv4_config != null ? [1] : []
          content {
            ipv4_address = local.ipv4_config.ip_address
            ipv4_netmask = local.ipv4_config.netmask
          }
        }
        
        ipv4_gateway    = local.ipv4_config != null ? local.ipv4_config.gateway : null
        dns_server_list = local.dns_config.dns_server_list
        dns_suffix_list = local.dns_config.dns_suffix_list
      }
    }
    
    dynamic "customize" {
      for_each = local.os_family == "windows" ? [1] : []
      content {
        windows_options {
          computer_name  = var.vm_name
          admin_password = var.windows_admin_password
          workgroup      = var.windows_workgroup != "" ? var.windows_workgroup : null
          join_domain    = var.domain != "" && var.windows_workgroup == "" ? var.domain : null
          domain_admin_user = var.domain != "" && var.windows_workgroup == "" ? var.domain_admin_user : null
          domain_admin_password = var.domain != "" && var.windows_workgroup == "" ? var.domain_admin_password : null
          time_zone      = var.windows_time_zone
          product_key    = var.windows_product_key
          organization_name = var.windows_organization_name
          auto_logon    = var.windows_auto_logon
          auto_logon_count = var.windows_auto_logon ? var.windows_auto_logon_count : 0
          run_once_command_list = var.windows_run_once_command_list
        }
        
        dynamic "network_interface" {
          for_each = local.ipv4_config != null ? [1] : []
          content {
            ipv4_address = local.ipv4_config.ip_address
            ipv4_netmask = local.ipv4_config.netmask
          }
        }
        
        ipv4_gateway    = local.ipv4_config != null ? local.ipv4_config.gateway : null
        dns_server_list = local.dns_config.dns_server_list
        dns_suffix_list = local.dns_config.dns_suffix_list
      }
    }
  }
  
  # VM Advanced configuration
  cpu_hot_add_enabled    = var.cpu_hot_add_enabled
  memory_hot_add_enabled = var.memory_hot_add_enabled
  
  # Handle VM notes/annotation
  annotation = var.annotation != "" ? var.annotation : "Managed by Terraform. VM Name: ${var.vm_name}, OS: ${var.os_family}, Created: ${timestamp()}"
  
  # Enable EFI if required (for secure boot and newer OS)
  firmware = var.enable_efi ? "efi" : "bios"
  
  # vApp properties if needed
  vapp {
    properties = var.vapp_properties
  }
  
  # Wait for guest IP address to be available
  wait_for_guest_net_timeout = var.wait_for_guest_net_timeout
  wait_for_guest_ip_timeout  = var.wait_for_guest_ip_timeout
  
  # Lifecycle policy - prevent destroying if protected
  lifecycle {
    prevent_destroy = var.prevent_destroy
    ignore_changes  = var.prevent_update ? all : []
  }
  
  # Integration with Infoblox - release IP on destroy
  provisioner "local-exec" {
    when    = destroy
    command = var.use_infoblox && !var.use_static_ip ? "${path.module}/scripts/release_infoblox_ip.sh ${self.default_ip_address}" : "echo 'Skipping Infoblox IP release'"
    interpreter = ["/bin/bash", "-c"]
  }
}