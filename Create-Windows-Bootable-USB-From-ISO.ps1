<#
 .SYNOPSIS
 A script to create an installation USB for Windows 2019 Server.
 .PARAMETER ISOImg
 The path to the Windows Server 2019 image.
 .PARAMETER DriveName
 The flash drive name. "Boot-Drive" is set by default.
 .PARAMETER BootType
 The boot type for the flash drive (UEFI or BIOS). UEFI is set by default.
 .EXAMPLE PS> .\Create-USB-Drive.ps1 -ISOImg "C:\Temp\Win_Srv_2019.iso" -DriveName "New Usb Drive Name" -BootType "Boot Type"
#>
 
# Specify parameters passed to the script as variables
param
(
[Parameter (Mandatory = $true)]
[String]$ISOImg,
[Parameter (Mandatory = $false)]
[String]$DriveName="Boot-Drive",
[Parameter (Mandatory = $false)]
[ValidateSet("BIOS","UEFI")]
[String]$BootType = "UEFI"
)
 
# Variable definition based on the boot type
if ($BootType -eq "UEFI")
     {
        $PartStyle="GPT"
        $FSType="FAT32"
        $IsPartActive=$false               
               }
                    else
                             {
                                 $PartStyle="MBR"
                                 $FSType="NTFS"
                                 $IsPartActive=$true
                                          }
 
# Clean the console to get started
Clear-Host
 
# Check whether a USB drive is connected to the system
if (!(Get-Disk | Where BusType -eq "USB" )) 
     {
        # Get the list of all drives
        Get-Disk | Format-Table -AutoSize Number,FriendlyName,BusType,@{Name="Size (GB)"; Expression={[int]($_.Size/1GB)}},PartitionStyle
                   
        # Delete local variables
        Remove-Variable -Name * -Force -ErrorAction SilentlyContinue
 
        # Pause before closing the console
        Write-Error "Flash drive not found! Please connect an appropriate one and run the script again!" | Pause | Clear-Host
        exit
               }  
                    else
                            {
                                # Get the list of USB drives
                                Get-Disk | Where BusType -eq "USB" | Format-Table -AutoSize Number,FriendlyName,@{Name="Size (GB)"; Expression={[int]($_.Size/1GB)}},PartitionStyle
 
                                # The cycle variable initialization
                                $Choice1=0
 
                                # Create the first input cycle
                                while (($Choice1).Equals(0)) 
                                        {
                                            # Get the number of the required USB drive from the user
                                            $NumOfDisk = Read-Host 'Type the number of the required disk from the list as a number. To exit the script, enter "Exit"'
 
                                            # Validation of entered data
                                            if (($NumOfDisk).Equals("E") -or ($NumOfDisk).Equals("e") -or ($NumOfDisk).Equals("Exit") -or ($NumOfDisk).Equals("exit") ) 
                                                 {
                                                       # Delete local variables
                                                       Remove-Variable -Name * -Force -ErrorAction SilentlyContinue
                                                       
                                                       # Pause before closing the console
                                                       Write-Warning "You have successfully terminated the script!" | Pause | Clear-Host 
                                                       Exit
                                                           } 
 
                                            # Get from the user the value for the variable name of the required USB drive
                                            $USBDrive = Get-Disk | Where Number -eq "$NumOfDisk"
                              
                                            # Check if disk variable has been input correctly
                                            if (($USBDrive).BusType -eq "USB" -and ($USBDrive).Number -notlike $null -and ($USBDrive).Number -gt "0" -and ([int]($USBDrive.Size/1GB)) -ge "7" )
                                                  {
                                                        # The cycle variable initialization
                                                        $Choice2=0
                    
                                                        # Create the second input cycle
                                                        while (($Choice2).Equals(0)) 
                                                                {
                                                                    # Reading data from the console to a variable
                                                                    $Confirm = Read-Host "You have selected the disk  ("($USBDrive).FriendlyName" ). All data on this disk will be deleted! Continue (Yes(Y) / No(N) / Exit(E))"
                           
                                                                    # Validation of the entered data 
                                                                    if (($Confirm).Equals("Y") -or ($Confirm).Equals("y") -or ($Confirm).Equals("Yes") -or ($Confirm).Equals("yes") ) 
                                                                           {
                                                                                $Choice1=1
                                                                                break
                                                                                    }
                                                                                        # Validation of the entered data
                                                                                        elseif (($Confirm).Equals("N") -or ($Confirm).Equals("n") -or ($Confirm).Equals("No") -or ($Confirm).Equals("no") ) 
                                                                                                {
                                                                                                    Write-Warning "Please choose another drive number!"
                                                                                                    $Choice2=1
                                                                                                    continue
                                                                                                               } 
                                                                                                                    # Validation of the entered data
                                                                                                                    elseif (($Confirm).Equals("E") -or ($Confirm).Equals("e") -or ($Confirm).Equals("Exit") -or ($Confirm).Equals("exit") ) 
                                                                                                                            { 
                                                                                                                                # Delete local variables
                                                                                                                                Remove-Variable -Name * -Force -ErrorAction SilentlyContinue
 
                                                                                                                                # Pause before closing the console
                                                                                                                                Write-Warning "You have successfully terminated the script!" | Pause | Clear-Host
                                                                                                                                exit
                                                                                                                                        } 
                                                                                                                                            else 
                                                                                                                                                    {
                                                                                                                                                          Write-Warning  "An invalid or unrecognizable input received! Please reenter the value."  
                                                                                                                            
                                                                                                                                                                 }  
                                                                                                                                                        } 
                                                                                                                                  }             
                                                                                                                                        else
                                                                                                                                                {
                                                                                                                                                    Write-Warning  "An invalid or unrecognized value was received, or the selected drive volume is less than 8GB! Please re-enter the value!"   
                                                                                                                                                         }
                                                                                                                                               }
 
# Delete data from the flash drive. Assign a partition style
$USBDrive | Clear-Disk -RemoveData -Verbose:$true -Confirm:$false -PassThru  | Set-Disk -PartitionStyle $PartStyle -WarningAction SilentlyContinue
 
# Create the partition. Formatting in a new file system 
$DrivePart = $USBDrive | New-Partition -Verbose:$true -UseMaximumSize -AssignDriveLetter -WarningAction SilentlyContinue | Format-Volume -Verbose:$true -Force:$true -FileSystem $FSType -NewFileSystemLabel $DriveName 
 
# Make a partition active 
$USBDrive | Get-Partition -Verbose:$true | Set-Partition -Confirm:$false -Verbose:$true -IsActive $IsPartActive
 
# Mount the installation image
$MntImg = Mount-DiskImage -ImagePath $ISOImg -StorageType ISO -PassThru
 
# Mount an image letter
$MntImgLetter = ($MntImg | Get-Volume).DriveLetter
 
# Assign a drive letter
$DriveLetter = ($DrivePart).DriveLetter
 
# Assign an installation disk letter
$InstFSize = Get-Childitem -Path $MntImgLetter":\sources\install.wim" | select length
    if ( ($BootType).Equals("BIOS") -and [int](($InstFSize).Length/1GB) -le "4") 
            {
                # Copy all files to the USB drive.
                Copy-Item -Verbose:$true -Force:$true -Recurse -Path ($MntImgLetter+":\*") -Destination ($DriveLetter+":\")
                        } 
                            else
                                   {
                                        # Copy all files to the USB drive except install.wim
                                        Copy-Item -Verbose:$true -Exclude "install.wim" -Recurse -Path ($MntImgLetter+":\*") -Destination ($DriveLetter+":\")
                                       
                                        # Initialize the temporary directory variable on the PC and Create a temporary directory on the PC
                                        ($TmpPcDir = $env:TEMP+"\DISMTMP\") | new-item -Path $TmpPcDir -Force:$true -Verbose:$true -itemtype directory | Out-Null
                                        
                                        # Split a Windows image file (install.wim) 
                                        Dism /Split-Image /ImageFile:$MntImgLetter":\sources\install.wim" /SWMFile:$TmpPcDir\install.swm /FileSize:3000 /English /Quiet
                                      
                                        # Transfer files to the flash drive
                                        Move-Item -Verbose:$true -Force:$true -Path ($TmpPcDir+"*") -Destination ($DriveLetter+":\sources\") 
                                                                                                                  
                                        # Delete the temporary directory
                                        Remove-Item $TmpPcDir -Force:$true -Verbose:$true -Recurse
                                               }
 
# Unmount the installation image
Dismount-DiskImage -Verbose:$true -ImagePath $ISOImg
 
# Delete local variables
Remove-Variable -Name * -Force -ErrorAction SilentlyContinue
 
                                                                        }
                                                                        
# Pause before closing the console
Write-Warning "The script has been successfully completed! Your bootable flash drive is ready to use!" | Pause | Clear-Host