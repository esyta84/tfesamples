# Windows-specific customization logic

locals {
  # Default Windows time zones if not specified
  windows_time_zones = {
    "eastern" = 85     # Eastern Standard Time
    "central" = 20     # Central Standard Time
    "mountain" = 10    # Mountain Standard Time
    "pacific" = 4      # Pacific Standard Time
    "utc" = 85         # UTC
  }
  
  # Default Windows time zone if not specified
  default_windows_time_zone = 85  # Eastern Standard Time
  
  # Prepare Windows customization commands
  windows_firstboot_commands = [
    # Enable Remote Desktop
    "powershell.exe -Command Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name 'fDenyTSConnections' -Value 0",
    "powershell.exe -Command Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'",
    
    # Set power options to high performance
    "powershell.exe -Command powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c",
    
    # Disable IPv6 (if needed)
    "powershell.exe -Command Disable-NetAdapterBinding -Name '*' -ComponentID 'ms_tcpip6'",
    
    # Disable IE Enhanced Security Configuration
    "powershell.exe -Command Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Active Setup\\Installed Components\\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' -Name 'IsInstalled' -Value 0",
    "powershell.exe -Command Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Active Setup\\Installed Components\\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' -Name 'IsInstalled' -Value 0",
    
    # Set Server Time Zone
    "powershell.exe -Command Set-TimeZone -Id 'Eastern Standard Time'"
  ]
  
  # Windows customization script for disk initialization
  windows_disk_init_script = <<-EOT
    <powershell>
    # Initialize, format, and mount additional disks
    Get-Disk | Where-Object PartitionStyle -eq 'RAW' | ForEach-Object {
        $DriveLetter = $null
        $DiskNumber = $_.Number
        
        # Initialize disk
        Initialize-Disk -Number $DiskNumber -PartitionStyle GPT -PassThru
        
        # Create partition with maximum size
        $Partition = New-Partition -DiskNumber $DiskNumber -UseMaximumSize
        
        # Format the volume
        $Volume = Format-Volume -Partition $Partition -FileSystem NTFS -NewFileSystemLabel "Data$DiskNumber" -Confirm:$false
        
        # Assign drive letter (starting from E:)
        $UsedDriveLetters = Get-Volume | Where-Object {$_.DriveLetter} | Select-Object -ExpandProperty DriveLetter
        $AvailableDriveLetters = [char[]](69..90) | Where-Object {$_ -notin $UsedDriveLetters}
        
        if ($AvailableDriveLetters) {
            $DriveLetter = $AvailableDriveLetters[0]
            Set-Partition -DiskNumber $DiskNumber -PartitionNumber $Partition.PartitionNumber -NewDriveLetter $DriveLetter
            Write-Output "Disk $DiskNumber initialized and mounted as ${DriveLetter}:"
        } else {
            Write-Output "Disk $DiskNumber initialized but no drive letter available"
        }
    }
    
    # Log completion
    $LogPath = "C:\Windows\Temp\DiskInitialization.log"
    "Disk initialization completed at $(Get-Date)" | Out-File -FilePath $LogPath -Append
    </powershell>
  EOT
  
  # Combine custom commands with default ones
  combined_windows_commands = distinct(concat(
    local.windows_firstboot_commands,
    var.windows_run_once_command_list
  ))
  
  # Include custom script in vApp properties
  windows_vapp_properties = var.os_family == "windows" ? merge(
    var.vapp_properties,
    {
      "guestinfo.userdata" = base64encode(local.windows_disk_init_script)
      "guestinfo.userdata.encoding" = "base64"
    }
  ) : var.vapp_properties
}

# Note: The actual Windows customization is handled in the main.tf clone block
# This file is primarily for Windows-specific logic that might be extended in the future