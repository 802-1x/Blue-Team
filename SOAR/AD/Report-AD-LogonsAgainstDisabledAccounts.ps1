<#
.SYNOPSIS 
    Identifies possible attacks against disabled AD user accounts.
	
.DESCRIPTION 
    AD query of bad logon attempts against disabled AD user objects. Emails results.
	
.NOTES 
	Author:		<redacted>
	Date:		October 4th 2022
	Notes:		Creation
#>

Import-Module ActiveDirectory

$Output = @()
$PreviousWeek = (Get-date).AddDays(-7)

$accountsOfInterest = Get-ADUser -Filter * -Property Name, BadLogonCount, Enabled, lockoutTime, LastBadPasswordAttempt, whenChanged | Where-Object {$_.Enabled -like "false" -and $_.BadLogonCount -gt 0 -and $_.LastBadPasswordAttempt -gt $_.whenChanged } | Select Name, Enabled, BadLogonCount, LockedOut, LastBadPasswordAttempt, whenChanged | sort LastBadPasswordAttempt -descending
$accountsOfInterest = $AccountsOfInterest | where { $_.LastBadPasswordAttempt -ge $PreviousWeek }

if ( $accountsOfInterest -eq $null ) { Exit }

foreach ($User in $accountsOfInterest) {

    $OutputInformation = [PSCustomObject]@{    
        Name = $User.Name
        Enabled = $User.Enabled
        BadLogonCount = $User.BadLogonCount
        LockedOut = $User.LockedOut
        LastBadPasswordAttempt = $User.LastBadPasswordAttempt
        whenChanged = $User.whenChanged
    }
    $Output += $OutputInformation

}

$Output = $Output | ConvertTo-HTML -Fragment

$body = @"
<html>  
  <body>
      Data sorted by LastBadPasswordAttempt attribute. Data will only appear if LastBadPasswordAttempt date greater than whenChanged attribute date and BadLogonCount greater than 0 value.<br><br>
      Line items can be cleared by going into Active Directory and using the 'Unlock account' tickbox under the Accounts tab, which will reset BadLogonCount back to 0 value. Not advised except if testing and monitoring as this will change the last modified date on the object.<br><br>
      Alternatively, check Event Viewer on the Domain Controllers for event ID 4625.<br><br>
      $Output
  </body>
</html>
"@

$params = @{
    Body = $Body
    BodyAsHtml = $true
    Subject = "Failed Logon Attempts on Disabled Accounts"
    From = '<redacted>'
    To = '<redacted>'
    SmtpServer = '<redacted>'
    Port = 25
}

Send-MailMessage @params
