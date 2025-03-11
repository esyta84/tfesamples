# Basic VM information
output "vm_id" {
  description = "The ID of the virtual machine"
  value       = vsphere_virtual_machine.vm.id
}

output "vm_name" {
  description = "The name of the virtual machine"
  value       = vsphere_virtual_machine.vm.name
}

output "vm_uuid" {
  description = "The UUID of the virtual machine"
  value       = vsphere_virtual_machine.vm.uuid
}

# Network information
output "ip_address" {
  description = "The primary IP address of the virtual machine"
  value       = vsphere_virtual_machine.vm.default_ip_address
}

output "mac_address" {
  description = "The MAC address of the primary network interface"
  value       = length(vsphere_virtual_machine.vm.network_interface) > 0 ? vsphere_virtual_machine.vm.network_interface[0].mac_address : ""
}

output "guest_ip_addresses" {
  description = "All IP addresses of the virtual machine from the VMware tools"
  value       = vsphere_virtual_machine.vm.guest_ip_addresses
}

# Infoblox information
output "infoblox_allocated_ip" {
  description = "The IP address allocated by Infoblox"
  value       = local.use_infoblox_ipam ? local.infoblox_allocated_ip : null
}

output "infoblox_dns_record" {
  description = "The DNS record created in Infoblox"
  value       = local.use_infoblox_ipam && var.create_dns_record ? local.dns_fqdn : null
}

output "infoblox_network_view" {
  description = "The Infoblox network view used"
  value       = local.use_infoblox_ipam ? var.infoblox_network_view : null
}

# Datastore information
output "datastore_name" {
  description = "The name of the datastore used"
  value = var.datastore_cluster_id != "" ? data.vsphere_datastore_cluster.datastore_cluster[0].name : (
    var.datastore_id != "" ? data.vsphere_datastore.datastores[var.datastore_id].name : (
      length(local.sorted_datastores) > 0 ? local.sorted_datastores[0].name : null
    )
  )
}

output "datastore_id" {
  description = "The ID of the datastore used"
  value       = vsphere_virtual_machine.vm.datastore_id
}

# Resource placement
output "resource_pool_id" {
  description = "The ID of the resource pool used"
  value       = vsphere_virtual_machine.vm.resource_pool_id
}

output "folder_path" {
  description = "The path of the folder where the VM is placed"
  value       = var.folder_path
}

# Configuration details
output "num_cpus" {
  description = "The number of CPUs assigned to the VM"
  value       = vsphere_virtual_machine.vm.num_cpus
}

output "memory_mb" {
  description = "The amount of memory assigned to the VM in MB"
  value       = vsphere_virtual_machine.vm.memory
}

# Disk information
output "disks" {
  description = "Information about all disks"
  value = [
    for idx, disk in vsphere_virtual_machine.vm.disk : {
      label       = disk.label
      size_gb     = disk.size
      unit_number = idx
    }
  ]
}

# OS information
output "os_family" {
  description = "The OS family of the VM"
  value       = var.os_family
}

output "guest_id" {
  description = "The guest ID of the VM"
  value       = vsphere_virtual_machine.vm.guest_id
}

# VM state
output "power_state" {
  description = "The power state of the VM"
  value       = vsphere_virtual_machine.vm.power_state
}