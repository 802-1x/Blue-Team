Import-Module ActiveDirectory
$UserRDPAuthEvents = Get-WinEvent -LogName ForwardedEvents | where {$_.Id -eq 1149} #| fl -Property *
$Output = @()
$OnsiteRDP =@()

foreach ($Event in $UserRDPAuthEvents) {

    Clear-Variable ADUser
    Clear-Variable PersonalDevice
    Clear-Variable OnsiteRDP
    $EventMessage = $Event.Message
    $EventMessage -replace "`t|`n|`r","" -match 'User:(.*?)Domain'
    $User = $matches[1]
    $EventMessage -replace "`t|`n|`r","" -match 'Address:(.*?)$'
    $Network = $matches[1]
    Try { $ADUser = Get-ADUser $User }
    Catch { $PersonalDevice = "Personal Device" }
    if ($Network -notlike "*x.x.x.*" -and $Network -notlike "*non-reverse routable vpn subnet" ) { $OnsiteRDP = "Onsite" }
    $CompShortName = $Event.MachineName.Substring(0, $Event.MachineName.IndexOf('.'))
    $ADCompDescr = Get-ADComputer $CompShortName -Properties Description
   
    $OutputHash = [PSCustomObject]@{
        TimeCreated = $Event.TimeCreated
        DisplayName = $ADUser.Name
        User = $User
        Description = $ADUser.Description
        SourceNetwork = $Network
        TargetMachine = $CompShortName
        TargetMachineDescr = $ADCompDescr.Description
        PersonalDevice = $PersonalDevice
        OnsiteRDP = $OnsiteRDP
    }
    $Output += $OutputHash

}

#$Output | ft

$FileName = "C:\Scripts\RDP\RDP_Logging_$(get-date -f yyyy-MM-dd).csv"

if (Test-Path -Path $FileName) {
    
    $Import_temp = Import-Csv -path $FileName
    $MergeToHistory = $Output + $Import_temp
    $MergeToHistory | Export-Csv -path $FileName -NoTypeInformation
    $MergeToHistorySorted = Import-Csv -path $FileName | sort TimeCreated, DisplayName, User, Description, SourceNetwork, TargetMachine, TargetMachineDescr, PersonalDevice, OnsiteRDP -Unique
    $MergeToHistorySorted | Export-Csv -path $FileName -NoTypeInformation

} else {

    $Output | Export-Csv -path $FileName -NoTypeInformation

}
