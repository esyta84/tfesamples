# Linux-specific customization logic

locals {
  linux_specific_script = <<-EOT
    #!/bin/bash
    # Custom configuration script for Linux VMs
    
    # Set hostname
    hostnamectl set-hostname ${var.vm_name}
    
    # Update /etc/hosts
    echo "127.0.0.1 ${var.vm_name}.${var.domain} ${var.vm_name}" >> /etc/hosts
    
    # Configure time synchronization
    timedatectl set-timezone UTC
    systemctl enable --now chronyd
    
    # Apply system updates
    if command -v dnf &> /dev/null; then
        # RHEL/CentOS 8+
        dnf -y update
    elif command -v yum &> /dev/null; then
        # RHEL/CentOS 7 and earlier
        yum -y update
    elif command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        apt-get update
        apt-get -y upgrade
    fi
    
    # Configure additional disks if present
    for disk in $(lsblk -dpno NAME | grep -v "$(df -h / | grep dev | cut -d' ' -f1)" | grep -E '^/dev/(sd|nvme|xvd)' | sort); do
        # Skip if disk is already formatted
        if ! blkid $disk &> /dev/null; then
            echo "Formatting disk $disk"
            parted $disk mklabel gpt
            parted $disk mkpart primary 0% 100%
            mkfs.xfs ${disk}1
            
            # Get UUID
            UUID=$(blkid -s UUID -o value ${disk}1)
            
            # Create mount point and add to fstab
            DIR="/data/disk_$(basename $disk)"
            mkdir -p $DIR
            echo "UUID=$UUID $DIR xfs defaults 0 0" >> /etc/fstab
        fi
    done
    
    # Mount all from fstab
    mount -a
    
    # Log completion
    echo "VM customization completed at $(date)" > /var/log/vm_customization.log
  EOT

  # Include custom script in vApp properties if EFI is enabled
  # (using vApp properties is one way to inject custom scripts)
  linux_vapp_properties = var.enable_efi && var.os_family == "linux" ? merge(
    var.vapp_properties,
    {
      "guestinfo.userdata" = base64encode(local.linux_specific_script)
      "guestinfo.userdata.encoding" = "base64"
    }
  ) : var.vapp_properties
}

# Note: The actual Linux customization is handled in the main.tf clone block
# This file is primarily for Linux-specific logic that might be extended in the future