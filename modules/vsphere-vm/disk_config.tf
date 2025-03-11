# Disk configuration logic

locals {
  # Validate disk configurations
  disk_validation = [
    for idx, disk in var.additional_disks : {
      valid_size         = disk.size_gb > 0
      valid_thin_eagerly = !(disk.thin_provisioned && disk.eagerly_scrub) # These are mutually exclusive
      valid_unit_number  = disk.unit_number == null || (disk.unit_number > 0 && disk.unit_number < 16)
    }
  ]

  # Check if any disk has invalid configuration
  has_invalid_disk = contains(
    flatten([
      for validation in local.disk_validation : [
        for key, valid in validation : valid
      ]
    ]),
    false
  )

  # Ensure root disk and additional disks don't have conflicting unit numbers
  unique_unit_numbers = length(
    distinct(
      concat(
        [0], # Root disk unit number
        [
          for disk in var.additional_disks :
          disk.unit_number != null ? disk.unit_number : 0
        ]
      )
    )
  ) == length(var.additional_disks) + 1

  # Auto assign unit numbers if not specified
  disks_with_unit_numbers = [
    for idx, disk in var.additional_disks : merge(
      disk,
      {
        unit_number = disk.unit_number != null ? disk.unit_number : idx + 1
        # If datastore_id is not specified, use the same as VM's primary datastore
        datastore_id = disk.datastore_id != null ? disk.datastore_id : null
      }
    )
  ]

  # Validate unit number assignment
  unit_number_clash = length(
    distinct([
      for disk in local.disks_with_unit_numbers : disk.unit_number
    ])
  ) != length(local.disks_with_unit_numbers)
}

# Check for various disk-related errors
resource "null_resource" "disk_validation_checks" {
  count = length(var.additional_disks) > 0 ? 1 : 0

  # This will cause a plan-time error if there are issues with disk configurations
  lifecycle {
    precondition {
      condition     = !local.has_invalid_disk
      error_message = "One or more additional disks have invalid configuration. Check size, thin_provisioned and eagerly_scrub settings."
    }

    precondition {
      condition     = !local.unit_number_clash
      error_message = "Disk unit numbers must be unique across all disks."
    }
  }
}