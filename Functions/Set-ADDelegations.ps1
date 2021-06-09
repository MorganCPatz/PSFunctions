#require -Modules ActiveDirectory

<#
.SYNOPOSIS
    Set AD Delegation(s) on Organizational Unit(s) for an Active Directory group
.PARAMETER DistinguishedName
    DistinguishedName of Organizational Unit to set delegations on
.PARAMETER ADGroupName
    AD Group that will be delegated permissions
.PARAMETER OUExclusionsDistinguishedName
    DistinguishedName of Organizational Units to be exluded from delegations
.EXAMPLE
  PS C:\> Set-ADDelegations -DistinguishedName 'OU=MyOU,DC=MyDomain,DC=com' -ADGroupName 'MyAdminUsers' -Delegation Computer
.EXAMPLE
  PS C:\> Get-ADOrganizationalUnit -Filter * -SearchScope OneLevel | Set-ADDelegations -ADGroupname 'MyAdminUsers' -OUExclusionDistinguishedName 'OU=Domain Controllers, DC=mydomain,DC=com' -Delegation User
.NOTES
  GUID values can be be found by searching previously delegated permissions (GET-ACL "OU").Access | Where-Object {$_.IdentityReference -like "Domain\Group"} or through Microsoft Documentation.
  Script provides framework to delegate basic AD Permissions - Values can be modified to suite specific needs.
.LINK 
    https://morgancpatz.github.io

#>

Function Set-ADDelegations {
 
    [CmdletBinding()]
    [OutputType()]
    param (
    [Parameter (
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
    [ValidateSet("Computer","User","Group","UnlockAccount")]
    [String]
    $Delegation,
    [Parameter()]
    [String[]]
    $OUExclusionDisgintuishedName
    
)
    begin {
        try {
            $identity = Get-ADGroup -Identity $ADGroupName | Select-Object -ExpandProperty SID -ErrorAction Stop
        } 
        catch {
            $PSCmdlet.ThrowTerminatingError(
            $_
        )
        break
        }

        #GUIds.
        $ComputerObj = New-Object GUID bf967a86-0de6-11d0-a285-00aa003049e2  ## Computer Class
        $UserObj = New-Object GUID bf967aba-0de6-11d0-a285-00aa003049e2      ## User Class
        $GroupObj = New-Object GUID bf967a9c-0de6-11d0-a285-00aa003049e2     ## Group Class
        $LockoutTime = New-Object GUID 28630ebf-41d5-11d1-a9c1-0000f80367c1  ##Lockout-Time Attribute

        #Base ACL.
        $adRights = [System.DirectoryServices.ActiveDirectoryRights] "CreateChild","DeleteChild"
        $RWProperty = [System.DirectoryServices.ActiveDirectoryRights] "ReadProperty","WriteProperty"
        $type = [System.Security.AccessCOntrol.AccessControlType] "Allow"
        $inheritanceTypeAll = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "1"
        $inhertianceTypeDesc = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "2"
    } 

    process {
        foreach ($dn in $DistinguishedName | Where {$OUExclusionDisgintuishedName -notcontains $_}){
        $path = "AD:\${dn}"
        $acl = Get-Acl -Path $path

        #Create ACLs.
        Switch ($Delegation)
        {
            ##Sets Full Control for Computer Objects
            Computer {
                $ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, $adRights, $type, $ComputerObj, $inheritanceTypeAll))
                $ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, "GenericAll", $type, $inhertianceTypeDesc, $ComputerObj))
                Set-Acl -Path $path -AclObject $acl
            }
            ##Sets Full Control for User Objects
            User {
                $ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, $adRights, $type, $UserObj, $inheritanceTypeAll))
                $ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, "GenericAll", $type, $inhertianceTypeDesc, $UserObj))
                Set-Acl -Path $path -AclObject $acl
            }
            ##Sets Full Control for Group Objects
            Group {
                $ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, $adRights, $type, $GroupObj, $inheritanceTypeAll)) 
                $ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, "GenericAll", $type, $inhertianceTypeDesc, $GroupObj))
                Set-Acl -Path $path -AclObject $acl
            }
            #Sets permissions to only unlock accounts
            UnlockAccount {
                $ACl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, $RWProperty, $type, $UserObj, $inheritanceTypeAll))
                Set-Acl -Path $path -AclObject $acl
            }
        }  
     }  
   }    
} 