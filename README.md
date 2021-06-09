# PowerShell Functions

---

Respository for holding PowerShell scripts-functions.  Any and all function(s) posted are very elementary but have served a purpose - it's all giant work in progress towards becoming more familiar and proficient in PowerShell.

---

### Create-VM
Creates VM(s) based on values input; can be used to create a single or multiple VMs with same specs.

```
PS C:\> Create-VM -VMNames $Names -StartupMemory 4GB -MaxiumumMemory 8GB -VHDSize 40GB -ISOPath 'C:\ISOS\Svr2019.ISO'
```

---

### Get-UpdateStatus
Generates a table containing the updates available in Software Center that have been deployed to devices in a SCCM Collection and emails the results.

```
PS C:\> Get-UpdateStatus -SiteServer 'SCCM-Server' -SiteCode 'MCP' -UpdateCollection 'Server Updates Manual Installation'
```

---

### Set-OUGPODelegations
Used to set GPO Delegations (Generate RSOP Planning/Logging, GP-Link, GP-Options) on all or select OUs for an AD Group.

```
PS C:\> Set-OUGPODelegations -DistinguishedName (Get-ADOrganizationalUnit -Identity 'OU=MyOU,DC=MyDomain,DC=com') -ADGroupName MyAdminUsers

PS C:\> Get-ADOrganizationalUnit -Filter * -SearchScope OneLevel | Set-OUGPODelegations -ADGroupName MyAdminUsers -OUExclusionDistinguishedName 'OU=Domain Controllers,DC=mydomain,DC=com'
```

---


### Set-ADDelegations
Used Set AD Delegation(s) (Full Control Computer/User/Group or Unlock User) on Organizational Unit(s) for an AD group. 


```
PS C:\> Set-ADDelegations -DistinguishedName 'OU=MyOU,DC=MyDomain,DC=com' -ADGroupName 'MyAdminUsers' -Delegation Computer

PS C:\> Get-ADOrganizationalUnit -Filter * -SearchScope OneLevel | Set-ADDelegations -ADGroupname MyAdminUsers -OUExclusionDistinguishedName 'OU=Domain Controllers, DC=mydomain,DC=com' -Delegation User
```

---
