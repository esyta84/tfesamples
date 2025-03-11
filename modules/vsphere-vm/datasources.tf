# vSphere data sources

# Get datacenter information
data "vsphere_datacenter" "dc" {
  name = var.datacenter_id
}

# Get cluster information
data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster_id
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Get VM template information
data "vsphere_virtual_machine" "template" {
  name          = var.template_id
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Get datastores matching the filter
data "vsphere_datastore" "datastores" {
  for_each      = toset(data.vsphere_datacenter.dc.datastore_ids)
  id            = each.key
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Filter datastores by regex
locals {
  filtered_datastores = {
    for id, ds in data.vsphere_datastore.datastores :
    id => ds if length(regexall(var.datastore_filter_regex, ds.name)) > 0
  }
}

# Get network information
data "vsphere_network" "network" {
  name          = var.network_id
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Get datastore cluster if specified
data "vsphere_datastore_cluster" "datastore_cluster" {
  count         = var.datastore_cluster_id != "" ? 1 : 0
  name          = var.datastore_cluster_id
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Get resource pool if specified
data "vsphere_resource_pool" "pool" {
  count         = var.resource_pool_id != "" ? 1 : 0
  name          = var.resource_pool_id
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Get VM folder if specified
data "vsphere_folder" "folder" {
  count         = var.folder_path != "" ? 1 : 0
  path          = var.folder_path
  datacenter_id = data.vsphere_datacenter.dc.id
  type          = "vm"
}