import-module DataONTAP

function msg($message) {
    Write-Host ""
    Write-Host "====================================================="
    Write-Host "$message"
    Write-Host "====================================================="
}

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

msg "Release SnapMirror Relationships on USOXF-NA07"
Invoke-NaSnapmirrorRelease -Source ($na07.Name + ":" + "vol1") -Destination ($na50.Name + ":" + "vol1_Mirror1") -Controller $na07 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($na07.Name + ":" + "vol2") -Destination ($na50.Name + ":" + "vol2_Mirror1") -Controller $na07 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($na07.Name + ":" + "/vol/vol3/qtree3") -Destination ($na50.Name + ":" + "/vol/vol3_Mirror1/qtree3") -Controller $na07 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($na07.Name + ":" + "/vol/vol4/qtree4") -Destination ($na50.Name + ":" + "/vol/vol4_Mirror1/qtree4") -Controller $na07 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($na07.Name + ":" + "vol5") -Destination ($na50.Name + ":" + "vol5_Mirror1") -Controller $na07 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($na07.Name + ":" + "vol6") -Destination ($na50.Name + ":" + "vol6_Mirror1") -Controller $na07 -Confirm:$false

msg "Release SnapMirror Relationships on USOXF-NA30"
Invoke-NaSnapmirrorRelease -Source ($na30.Name + ":" + "vol1_Mirror1") -Destination ($na50.Name + ":" + "vol1_Mirror1") -Controller $na30 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($na30.Name + ":" + "vol2_Mirror1") -Destination ($na50.Name + ":" + "vol2_Mirror1") -Controller $na30 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($na30.Name + ":" + "vol3_Mirror1") -Destination ($na50.Name + ":" + "vol3_Mirror1") -Controller $na30 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($na30.Name + ":" + "vol4_Mirror1") -Destination ($na50.Name + ":" + "vol4_Mirror1") -Controller $na30 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($na30.Name + ":" + "vol5_Mirror1") -Destination ($na50.Name + ":" + "vol5_Mirror1") -Controller $na30 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($na30.Name + ":" + "vol6_Mirror1") -Destination ($na50.Name + ":" + "vol6_Mirror1") -Controller $na30 -Confirm:$false

msg "Remove SnapMirror Schedules on USEDN-NA50"
Remove-NaSnapMirrorSchedule -Controller $na50 -Destination ($na50.Name + ":" + "vol1_Mirror1")
Remove-NaSnapMirrorSchedule -Controller $na50 -Destination ($na50.Name + ":" + "vol2_Mirror1")
Remove-NaSnapMirrorSchedule -Controller $na50 -Destination ($na50.Name + ":" + "/vol/vol3_Mirror1/qtree3")
Remove-NaSnapMirrorSchedule -Controller $na50 -Destination ($na50.Name + ":" + "/vol/vol4_Mirror1/qtree4")
Remove-NaSnapMirrorSchedule -Controller $na50 -Destination ($na50.Name + ":" + "vol5_Mirror1")
Remove-NaSnapMirrorSchedule -Controller $na50 -Destination ($na50.Name + ":" + "vol6_Mirror1")

msg "Remove volumes on USEDN-NA50"
Set-Navol vol1_Mirror1 -Offline -Controller $na50 | Remove-NaVol -Controller $na50 -Confirm:$false
Set-Navol vol2_Mirror1 -Offline -Controller $na50 | Remove-NaVol -Controller $na50 -Confirm:$false
Set-Navol vol3_Mirror1 -Offline -Controller $na50 | Remove-NaVol -Controller $na50 -Confirm:$false
Set-Navol vol3_Mirror1_mir -Offline -Controller $na50 | Remove-NaVol -Controller $na50 -Confirm:$false
Set-Navol vol4_Mirror1 -Offline -Controller $na50 | Remove-NaVol -Controller $na50 -Confirm:$false
Set-Navol vol5_Mirror1 -Offline -Controller $na50 | Remove-NaVol -Controller $na50 -Confirm:$false
Set-Navol vol6_Mirror1 -Offline -Controller $na50 | Remove-NaVol -Controller $na50 -Confirm:$false
Set-Navol vol6_Mirror1_mir -Offline -Controller $na50 | Remove-NaVol -Controller $na50 -Confirm:$false

msg "Release SnapMirror Relationships on USOXF-NA07"
Invoke-NaSnapmirrorRelease -Source ($ntap07 + ":" + "vol1") -Destination ($ntap30 + ":" + "vol1_Mirror1") -Controller $na07 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($ntap07 + ":" + "vol2") -Destination ($ntap30 + ":" + "vol2_Mirror1") -Controller $na07 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($ntap07 + ":" + "/vol/vol3/qtree3") -Destination ($ntap30 + ":" + "/vol/vol3_Mirror1/qtree3") -Controller $na07 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($ntap07 + ":" + "/vol/vol4/qtree4") -Destination ($ntap30 + ":" + "/vol/vol4_Mirror1/qtree4") -Controller $na07 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($ntap07 + ":" + "vol5") -Destination ($ntap30 + ":" + "vol5_Mirror1") -Controller $na07 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($ntap07 + ":" + "vol6") -Destination ($ntap30 + ":" + "vol6_Mirror1") -Controller $na07 -Confirm:$false

msg "Remove SnapMirror Schedules on USEDN-NA30"
Remove-NaSnapMirrorSchedule -Controller $na30 -Destination ($ntap30 + ":" + "vol1_Mirror1")
Remove-NaSnapMirrorSchedule -Controller $na30 -Destination ($ntap30 + ":" + "vol2_Mirror1")
Remove-NaSnapMirrorSchedule -Controller $na30 -Destination ($ntap30 + ":" + "/vol/vol3_Mirror1/qtree3")
Remove-NaSnapMirrorSchedule -Controller $na30 -Destination ($ntap30 + ":" + "/vol/vol4_Mirror1/qtree4")
Remove-NaSnapMirrorSchedule -Controller $na30 -Destination ($ntap30 + ":" + "vol5_Mirror1")
Remove-NaSnapMirrorSchedule -Controller $na30 -Destination ($ntap30 + ":" + "vol6_Mirror1")

msg "Remove volumes on USOXF-NA07 and USEDN-NA30"
Set-Navol vol1_Mirror1 -Offline -Controller $na30 | Remove-NaVol -Controller $na30 -Confirm:$false
Set-Navol vol2_Mirror1 -Offline -Controller $na30 | Remove-NaVol -Controller $na30 -Confirm:$false
Set-Navol vol3_Mirror1 -Offline -Controller $na30 | Remove-NaVol -Controller $na30 -Confirm:$false
Set-Navol vol4_Mirror1 -Offline -Controller $na30 | Remove-NaVol -Controller $na30 -Confirm:$false
Set-Navol vol5_Mirror1 -Offline -Controller $na30 | Remove-NaVol -Controller $na30 -Confirm:$false
Set-Navol vol6_Mirror1 -Offline -Controller $na30 | Remove-NaVol -Controller $na30 -Confirm:$false
Set-Navol vol1 -Offline -Controller $na07 | Remove-NaVol -Controller $na07 -Confirm:$false
Set-Navol vol2 -Offline -Controller $na07 | Remove-NaVol -Controller $na07 -Confirm:$false
Set-Navol vol3 -Offline -Controller $na07 | Remove-NaVol -Controller $na07 -Confirm:$false
Set-Navol vol4 -Offline -Controller $na07 | Remove-NaVol -Controller $na07 -Confirm:$false
Set-Navol vol5 -Offline -Controller $na07 | Remove-NaVol -Controller $na07 -Confirm:$false
Set-Navol vol6 -Offline -Controller $na07 | Remove-NaVol -Controller $na07 -Confirm:$false
