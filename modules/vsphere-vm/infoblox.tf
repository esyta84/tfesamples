# Local for tracking if Infoblox should be used
locals {
  use_infoblox_ipam = var.use_infoblox && var.infoblox_grid_host != "" && var.infoblox_username != "" && var.infoblox_password != ""

  # Extract network and CIDR from the infoblox_network
  infoblox_network_cidr = var.infoblox_network != "" ? split("/", var.infoblox_network)[1] : ""
  infoblox_network_addr = var.infoblox_network != "" ? split("/", var.infoblox_network)[0] : ""

  # IP allocation result placeholder
  infoblox_allocated_ip = local.use_infoblox_ipam ? (
    var.infoblox_reserve_ip && var.infoblox_reserved_ip != "" ? var.infoblox_reserved_ip : data.external.infoblox_ip[0].result.ipv4_address
  ) : ""

  # DNS configuration
  dns_hostname = var.vm_name
  dns_fqdn     = var.domain != "" ? "${var.vm_name}.${var.domain}" : var.vm_name
}

# Infoblox provider configuration
provider "infoblox" {
  # Only configure if we're using Infoblox
  count = local.use_infoblox_ipam ? 1 : 0

  server     = var.infoblox_grid_host
  username   = var.infoblox_username
  password   = var.infoblox_password
  ssl_verify = false
}

# Generate random hostname suffix if needed
resource "random_string" "hostname_suffix" {
  count   = local.use_infoblox_ipam ? 1 : 0
  length  = 6
  special = false
  upper   = false
}

# External data source to allocate IP from Infoblox
# This is used instead of the provider because we need more flexibility
data "external" "infoblox_ip" {
  count   = local.use_infoblox_ipam && !var.infoblox_reserve_ip ? 1 : 0
  program = ["${path.module}/scripts/allocate_infoblox_ip.sh"]

  query = {
    grid_host    = var.infoblox_grid_host
    username     = var.infoblox_username
    password     = var.infoblox_password
    network      = var.infoblox_network
    network_view = var.infoblox_network_view
    hostname     = local.dns_hostname
    domain       = var.domain
    tenant_id    = var.infoblox_tenant_id
    vm_name      = var.vm_name
    os_type      = var.os_family
    # Convert extensible attributes to JSON
    ext_attrs = jsonencode(var.infoblox_extensible_attributes)
  }
}

# Reserve a specific IP in Infoblox if requested
resource "infoblox_ip_allocation" "reserved_ip" {
  count = local.use_infoblox_ipam && var.infoblox_reserve_ip && var.infoblox_reserved_ip != "" ? 1 : 0

  network_view = var.infoblox_network_view
  ipv4_addr    = var.infoblox_reserved_ip
  mac_addr     = var.mac_address
  vm_name      = var.vm_name

  # Add extensible attributes
  dynamic "ext_attrs" {
    for_each = var.infoblox_extensible_attributes
    content {
      name  = ext_attrs.key
      value = ext_attrs.value
    }
  }
}

# Create DNS record in Infoblox
resource "infoblox_a_record" "dns" {
  count = local.use_infoblox_ipam && var.create_dns_record ? 1 : 0

  dns_view = var.infoblox_dns_view
  name     = local.dns_fqdn
  ipv4addr = local.infoblox_allocated_ip
  ttl      = var.infoblox_ttl

  # Add extensible attributes
  dynamic "ext_attrs" {
    for_each = var.infoblox_extensible_attributes
    content {
      name  = ext_attrs.key
      value = ext_attrs.value
    }
  }

  # Only create after IP allocation
  depends_on = [
    data.external.infoblox_ip,
    infoblox_ip_allocation.reserved_ip
  ]
}

# Create PTR record in Infoblox
resource "infoblox_ptr_record" "ptr" {
  count = local.use_infoblox_ipam && var.create_dns_record ? 1 : 0

  dns_view = var.infoblox_dns_view
  ptrdname = local.dns_fqdn
  ipv4addr = local.infoblox_allocated_ip

  # Add extensible attributes
  dynamic "ext_attrs" {
    for_each = var.infoblox_extensible_attributes
    content {
      name  = ext_attrs.key
      value = ext_attrs.value
    }
  }

  # Only create after A record
  depends_on = [infoblox_a_record.dns]
}