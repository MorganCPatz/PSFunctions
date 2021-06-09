#require -Modules ActiveDirectory

<#
.SYNOPSIS
    
    Set GPO Delegations on Organizational Unit(s) for an Active Directory group

.PARAMETER DistinguishedName

    DistinguishedName of Organizational Unit to set delegations on

.PARAMETER ADGroupName

    AD Group that will be delegated permissions

.PARAMETER OUExclusionsDistinguishedName
    
    DistinguishedName of Organizational Units to be exluded from delegations

.EXAMPLE

  PS C:\> Set-OUGPODelegations -DistinguishedName ( Get-ADOrganizationalUnit -Identity 'OU=MyOU,DC=MyDomain,DC=com') -ADGroupName MyAdminUsers

.EXAMPLE

  PS C:\> Get-ADOrganizationalUnit -Filter * -SearchScope OneLevel | Set-OUGPODelegations -ADGroupname MyAdminUsers -OUExclusionDistinguishedName 'OU=Domain Controllers, DC=mydomain,DC=com'

.LINK 

    https://morgancpatz.github.io

#>

function Set-OUGPODelegations {
  
  [CmdletBinding()]
  [OUtputType()]
  
  param (
    [Parameter(
      Mandatory = $true,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true
    )]
    [String[]]
    $DistinguishedName,
    
    [Parameter()]
    [ValidateNotNull()]
    [String]
    $ADGroupName,
    
    [Parameter()]
    [String[]]
    $OUExclusionDistinguishedName
 )
   
    begin {
      # ADGroup SID.
      try {
        $identity = Get-ADGroup -Identity $ADGroupName | Select-Object -ExpandProperty SID -ErrorAction Stop
      } catch {
        $PSCmdlet.ThrowTerminatingError(
          $_  
        )
        break
      }
      
      # GUIds.
      $gRSOPLogging = New-Object GUID b7b1b3de-ab09-4242-9e30-9980e5d322f7
      $gRSOPPlanning = New-Object GUID b7b1b3dd-ab09-4242-9e30-9980e5d322f7
      $gpOptions = New-Object GUID f30e3bbf-9ff0-11d1-b603-0000f80367c1
      $gpLink = New-Object GUID f30e3bbe-9ff0-11d1-b603-0000f80367c1
      
      # Base ACL.
      $adRights = [System.DirectoryServices.ActiveDirectoryRights] "ExtendedRight"
      $type = [System.Security.AccessControl.AccessControlType] "Allow"
      $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All"

    }
    
    process {     
       foreach ($dn in $DistinguishedName | Where {$OUExclusionDistinguishedName -notcontains $_}){ 
        $path = "AD:\${dn}"
        $acl = Get-ACl -Path $path
        
        # Create ACL.
        $ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, $adRights, $type, $gRSOPLogging, $inheritanceType))
        $ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, $adRights, $type, $gRSOPPlanning, $inheritanceType))
        $ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, "GenericAll", $type, $gpOptions, $inheritanceType))
        $ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, "GenericAll", $type, $gpLink, $inheritanceType))
        
        Set-ACL -Path $path -AclObject $acl 
      }
    }
}