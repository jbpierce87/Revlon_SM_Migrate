import-module DataONTAP

### Functions
function msg($message) {
    Write-Host ""
    Write-Host "====================================================="
    Write-Host "$message"
    Write-Host "====================================================="
}

### Controller Login Variables
$ntapuser = "root"
$ntappw = "AcmeL4b#"

### Convert Password to plain text
$pw = convertto-securestring $ntappw -asplaintext -force
$cred = new-object -typename system.management.automation.pscredential -argumentlist $ntapuser,$pw

### Connect to the controllers 
$na07 = Connect-NaController usedn-na07 -Credential $cred -https
$na30 = Connect-NaController usedn-na30 -Credential $cred -https
$na50 = Connect-NaController usedn-na50 -Credential $cred -https

msg "Release SnapMirror Relationships on USOXF-NA07"
Invoke-NaSnapmirrorRelease -Source ($na07.Name + ":" + "vol5") -Destination ($na50.Name + ":" + "vol5_Mirror1") -Controller $na07 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($na07.Name + ":" + "vol6") -Destination ($na50.Name + ":" + "vol6_Mirror1") -Controller $na07 -Confirm:$false

msg "Release SnapMirror Relationships on USOXF-NA30"
Invoke-NaSnapmirrorRelease -Source ($na30.Name + ":" + "vol5_Mirror1") -Destination ($na50.Name + ":" + "vol5_Mirror1") -Controller $na30 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($na30.Name + ":" + "vol6_Mirror1") -Destination ($na50.Name + ":" + "vol6_Mirror1") -Controller $na30 -Confirm:$false

msg "Remove SnapMirror Schedules on USEDN-NA50"
Remove-NaSnapMirrorSchedule -Controller $na50 -Destination ($na50.Name + ":" + "vol5_Mirror1")
Remove-NaSnapMirrorSchedule -Controller $na50 -Destination ($na50.Name + ":" + "vol6_Mirror1")

msg "Remove volumes on USEDN-NA50"
Set-Navol vol5_Mirror1 -Offline -Controller $na50 | Remove-NaVol -Controller $na50 -Confirm:$false
Set-Navol vol6_Mirror1 -Offline -Controller $na50 | Remove-NaVol -Controller $na50 -Confirm:$false

