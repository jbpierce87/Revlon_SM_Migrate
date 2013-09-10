import-module DataONTAP

### Controller Login Variables

$ntap30 = "usedn-na30"
$ntap50 = "usedn-na50"
$ntap07 = "usoxf-na07"

$ntapuser = "root"
$ntappw = "AcmeL4b#"

### Convert Password to plain text
$pw = convertto-securestring $ntappw -asplaintext -force
$cred = new-object -typename system.management.automation.pscredential -argumentlist $ntapuser,$pw

### Connect to the controllers 
$na07 = Connect-NaController $ntap07 -Credential $cred -https
$na30 = Connect-NaController $ntap30 -Credential $cred -https
$na50 = Connect-NaController $ntap50 -Credential $cred -https

Write-Host "====================================================="
Write-Host "Release SnapMirror Relationships on USOXF-NA07"
Write-Host "====================================================="
Invoke-NaSnapmirrorRelease -Source ($ntap07 + ":" + "vol5") -Destination ($ntap30 + ":" + "vol5_Mirror1") -Controller $na07 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($ntap07 + ":" + "vol6") -Destination ($ntap30 + ":" + "vol6_Mirror1") -Controller $na07 -Confirm:$false

Write-Host ""
Write-Host "====================================================="
Write-Host "Remove SnapMirror Schedules on USEDN-NA30"
Write-Host "====================================================="
Remove-NaSnapMirrorSchedule -Controller $na30 -Destination ($ntap30 + ":" + "vol5_Mirror1") #| Remove-NaSnapMirrorSchedule
Remove-NaSnapMirrorSchedule -Controller $na30 -Destination ($ntap30 + ":" + "vol6_Mirror1") #| Remove-NaSnapMirrorSchedule

Write-Host ""
Write-Host "====================================================="
Write-Host "Remove volumes on USOXF-NA07 and USEDN-NA30"
Write-Host "====================================================="
get-navol -controller $na07
Get-NaVol -Name vol5 -Controller $na07 | Set-NaVol -Offline -Name $_.Name
Get-NaVol -Name vol6 -Controller $na07 | Set-NaVol -Offline -Name $_.Name
get-navol -controller $na30
Get-NaVol -Name vol5_Mirror1 -Controller $na30 | Set-NaVol -Offline | Remove-NaVol
Get-NaVol -Name vol6_Mirror1 -Controller $na30 | Set-NaVol -Offline | Remove-NaVol


