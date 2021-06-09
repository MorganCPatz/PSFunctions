<#
.SYNOPSIS

    Creates Hyper-V VM(s) based on input values, enables secure boot, and sets first boot device to the VM DvdDrive

.PARAMETER VMNames

    Variable or Name(s) of Virtual Machines to be created

.PARAMETER StartupMemory

    Sets the startup memory size for each VM

.PARAMETER MaximumMemory

    Sets the Maximum Memory size for each VM

.PARAMETER VHDSize

    Sets the VHD Size for each VM

.PARAMETER ISOPath

    Path to the ISO to be loaded into the VM Drive

.EXAMPLE

    PS C:\> .\Create-VM.ps1 -VMNames $Names -StartupMemory 4GB -MaximumMemory 8GB -VHDSize 40GB -ISOPath 'C:\ISOs\WinSvr2019.ISO'

.EXAMPLE

    PS C:\> .\Create-VM.ps1 -VMNames 'Test-W10' -StartupMemory 4GB -MaximumMemory 8GB -VHDSize 40GB -ISOPath 'C:\ISOs\Win101809.ISO'

.NOTES

    VSiwtches are created based on specific NetAdapter Names - values may need to be adjusted

.Link

    https://morgancpatz.github.io

#>
Param (
    [Parameter(
        Mandatory = $true
    )]
    [Object]
    $VMNames,
    
    [Parameter(
        Mandatory = $true
    )]
    [Int64]
    $StartupMemory,

    [Parameter(
        Mandatory = $true
    )]
    [Int64]
    $MaximumMemory,

    [Parameter(
        Mandatory = $true
    )]
    [UInt64]
    $VHDSize,

    [Parameter(
        Mandatory = $true
    )]
    [String]
    $ISOPath

)

#Check for NetAdapter Names and Set Variables
$Ethernet = (Get-NetAdapter | Where-Object -Property Name -eq 'Ethernet')
$WirelessNIC = (Get-NetAdapter | Where-Object -Property Name -EQ 'Wi-Fi')

#Check for VMSwitch Names and Set Variables
$VSEthernet = (Get-VMSwitch | Where-Object -Property Name -eq 'VS-EXT ETH')
$VSWiFi = (Get-VMSwitch | Where-Object -Property Name -eq 'VS-EXT WiFi')

#Create Ethernet Virtual Switch
If ($VSEthernet)
{
    Write-Host 'VS-EXT ETH Already Exists'
}
elseif (-not $Ethernet)
{
    Write-Host 'NetAdapter Ethernet Does not Exist'
}
else
{
    New-VMSwitch -Name 'VS-EXT ETH' -NetAdapterName $EthNIC -AllowManagementOS $true
    Write-Host 'Created New Virtual Switch "VS-EXT ETH"'
}

#Create WiFi Virtual Switch
If ($WirelessNIC)
{
    Write-Host 'VS-EXT-WiFi Already Exists'
}
elseif (-not $WirelessNIC)
{
    Write-Host 'NetAdapter Wi-Fi Does not Exist'
}
else 
{
    New-VMSwitch -Name 'VS-EXT-WiFi' -NetAdapterName Wi-Fi -AllowManagementOS $true
    Write-Host 'Created New Virtaul Switch "VS-EXT-WiFi"'
}

#Get Default Paths for VirtualHardDisk and VirtualMachine
$VHDPath = Get-VMHost | Select-Object -ExpandProperty VirtualHardDiskPath
$VMPath = Get-VMHost | Select-Object -ExpandProperty VirtualMachinePath

#Create VMs and Set Applicable Settings
ForEach ($VM in $VMNames)
{
New-VM -Name $VM -MemoryStartupBytes $StartupMemory -BootDevice VHD -NewVHDPath $VHDPath\$VM.vhdx -Path $VMPath\VMData -NewVHDSizeBytes $VHDSize -Generation 2 -SwitchName $VSEthernet.Name
Set-VMMemory -VMName $VMNames -MaximumBytes $MaximumMemory
Add-VMDvdDrive -VMName $VM -Path $ISOPath 
$VMDVDDrive = Get-VM $VM | Get-VMDvdDrive
Set-VMFirmware $VM -EnableSecureBoot On -FirstBootDevice $VMDVDDrive 
Set-VM $VM -AutomaticCheckpointsEnabled $false
}