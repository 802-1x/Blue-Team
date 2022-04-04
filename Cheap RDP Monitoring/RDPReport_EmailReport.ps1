$Yesterday = (Get-Date).AddDays(-1)
$FileName = "C:\Scripts\RDP\RDP_Logging_$(Get-Date $Yesterday -f yyyy-MM-dd).csv"

$Attachment = "$FileName"

$Body = @"
    See attached for yesterday's RDP logs.
"@

$params = @{
    Attachment = $Attachment
    Body = $Body
    Subject = "Yesterday's RDP Log"
    From = 'grc@domain'
    To = '_NetworkNotifications@domain'
    #To = 'me@domain'
    SmtpServer = 'SMTPSERVER'
    Port = 25
}

Send-MailMessage @params
#Write-Host Sending $NetworkFriendlyName email report -ForegroundColor Green -BackgroundColor Blue
