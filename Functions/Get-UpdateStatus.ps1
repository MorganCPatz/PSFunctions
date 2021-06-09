<#

.SYNOPSIS

    Generates a table containing the updates available in Software Center that have been deployed to devices in a SCCM Collection and emails the results

.PARAMETER SiteServer

    SCCM Site Server Name

.PARAMETER SiteCode

    SCCM Site Code

.PARAMETER UpdateCollection

    Name of SCCM Collection to check for Update Status

.EXAMPLE

    PS C:\> .\Get-UpdateStatus.ps1 -SiteServer 'SCCM-Server' -SiteCode 'MCP' -UpdateCollection 'Server Updates Manual Installation'

.NOTES

    WMI is used to gather information, the account running the script needs appropriate access to the SCCM Site Server and associated servers
    Values for the message body need to be updated prior to running script, see Line #111 for more information



#>

Param
    (
    [Parameter(
        Mandatory = $true
    )]
    [String]
    $SiteServer,

    [Parameter(
        Mandatory = $true
    )]
    [String]
    $SiteCode,

    [Parameter(
        Mandatory = $true
    )]
    [String]
    $UpdateCollection
)

#Attempt to connect to the SCCM SiteServer and get members of the specified Collection

Try
{
    $ErrorActionPreference = "Stop"
    $UpdateCollectionResult = Get-WmiObject -ComputerName $SiteServer -Namespace ROOT\SMS\SITE_$SiteCode -Class SMS_Collection -Filter "Name = '$UpdateCollection'"
    $UpdateCollectionID = $UpdateCollectionResult.CollectionID
    $CollectionMembers = Get-WmiObject -ComputerName $SiteServer -Namespace ROOT\SMS\SITE_$SiteCode -Class SMS_CollectionMember_A -Filter "CollectionID = '$UpdateCollectionID'"
}
Catch 
{
    throw $_
}

$Servers = $CollectionMembers.Name
$ServerErrorArray = @()

#Connect to each server and gather update information

$Updates = foreach ($server in $Servers)
{
    Try
    {
    Get-WmiObject -ComputerName $server -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate | Where-Object {$_.ComplianceState -eq "0"} | Select @{Name = 'Client';Expression = {$server}}, Name, ArticleID, EvaluationState, StartTime -ErrorAction Stop
    }
    Catch
    {
    $ServerErrorArray += New-Object PSObject -Property ([ordered]@{Client = $server; Exception = $_.Exception.Message})
    }
}


$UpdateStatus = $Updates | Select *

$OutputToEmail = foreach ($us in $UpdateStatus) {

    if ($null -ne $us.EvaluationState) {
        $Time = $us.StartTime.Split('.')[0]

        [PSCustomObject]@{
            Server = $us.Client
            Update = $us.Name
            ArticleID = $us.ArticleID
            UpdateAvailable = [datetime]::ParseExact($Time, 'yyyyMMddHHmmss',$null)
            }
    }
}
    

#Creates and sets the format used for the Table
$style = "<style>BODY{font-family: Arial; font-size 10pt;}"
$style += "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style += "TH{border: 1px solid black; background: #dddddd; padding: 5px: }"
$style += "TD{border: 1px solid black; padding: 5px; }"
$style += "</style>"

$smtpServer = "<SMTP Server Address>"
$message = New-Object Net.Mail.MailMessage
$smtp = New-Object Net.Mail.SMTPClient($smtpServer)

#Creates the body and message of the email.  Update values in " " to reflect your environment
$message.From = "<Address to send email from>"
$message.To.Add("<Enter Recipient's Address>")
$message.Subject = "<Email Subject>"
$message.IsBodyHTML = $true
$message.Body = "<br>-----BEGIN AUTOMATED MESSAGE-----<br>"
$message.Body += "<br> Please install updates for these servers as soon as possible:<br><br>"
$message.Body += ($OutputToEmail | Sort-Object Server | ConvertTo-Html -Head $style)
$message.Body += "<br> The following servers could not be contacted.  Please check for pending updates:<br><br>"
$message.Body += ($ServerErrorArray | Sort-Object Client | ConvertTo-Html -Head $style)
$message.Body += "<br>-----END AUTOMATED MESSAGE-----<br>"

$smtp.Send($message)