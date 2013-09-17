import-module DataONTAP

### Controller Login Variables
$ntapuser = "root"
$ntappw = "AcmeL4b#"

### Convert Password to plain text
$pw = convertto-securestring $ntappw -asplaintext -force
$cred = new-object -typename system.management.automation.pscredential -argumentlist $ntapuser,$pw

### Connect to the controllers 
$na30 = Connect-NaController usedn-na30 -Credential $cred -https
$na50 = Connect-NaController usedn-na50 -Credential $cred -https

Write-Host "====================================================="
Write-Host "Release SnapMirror Relationships on USOXF-NA30"
Write-Host "====================================================="
Invoke-NaSnapmirrorRelease -Source ($na30.Name + ":" + "vol5_Mirror1") -Destination ($na50.Name + ":" + "vol5_Mirror1") -Controller $na30 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($na30.Name + ":" + "vol6_Mirror1") -Destination ($na50.Name + ":" + "vol6_Mirror1") -Controller $na30 -Confirm:$false

Write-Host "====================================================="
Write-Host "Remove SnapMirror Schedules on USEDN-NA50"
Write-Host "====================================================="
Remove-NaSnapMirrorSchedule -Controller $na50 -Destination ($na50.Name + ":" + "vol5_Mirror1")
Remove-NaSnapMirrorSchedule -Controller $na50 -Destination ($na50.Name + ":" + "vol6_Mirror1")

Write-Host "====================================================="
Write-Host "Remove volumes on USEDN-NA50"
Write-Host "====================================================="
Set-Navol vol5_Mirror1 -Offline -Controller $na50 | Remove-NaVol -Controller $na50 -Confirm:$false
Set-Navol vol6_Mirror1 -Offline -Controller $na50 | Remove-NaVol -Controller $na50 -Confirm:$false

