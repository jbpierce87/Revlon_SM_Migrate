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
#Invoke-NaSnapmirrorRelease -Source ($ntap07 + ":" + "vol1") -Destination ($ntap30 + ":" + "vol1_Mirror1") -Controller $na07 -Confirm:$false
#Invoke-NaSnapmirrorRelease -Source ($ntap07 + ":" + "vol2") -Destination ($ntap30 + ":" + "vol2_Mirror1") -Controller $na07 -Confirm:$false
#Invoke-NaSnapmirrorRelease -Source ($ntap07 + ":" + "/vol/vol3/qtree3") -Destination ($ntap30 + ":" + "/vol/vol3_Mirror1/qtree3") -Controller $na07 -Confirm:$false
#Invoke-NaSnapmirrorRelease -Source ($ntap07 + ":" + "/vol/vol4/qtree4") -Destination ($ntap30 + ":" + "/vol/vol4_Mirror1/qtree4") -Controller $na07 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($ntap07 + ":" + "vol5") -Destination ($ntap30 + ":" + "vol5_Mirror1") -Controller $na07 -Confirm:$false
Invoke-NaSnapmirrorRelease -Source ($ntap07 + ":" + "vol6") -Destination ($ntap30 + ":" + "vol6_Mirror1") -Controller $na07 -Confirm:$false

Write-Host "====================================================="
Write-Host "Remove SnapMirror Schedules on USEDN-NA30"
Write-Host "====================================================="
#Remove-NaSnapMirrorSchedule -Controller $na30 -Destination ($ntap30 + ":" + "vol1_Mirror1")
#Remove-NaSnapMirrorSchedule -Controller $na30 -Destination ($ntap30 + ":" + "vol2_Mirror1")
#Remove-NaSnapMirrorSchedule -Controller $na30 -Destination ($ntap30 + ":" + "/vol/vol3_Mirror1/qtree3")
#Remove-NaSnapMirrorSchedule -Controller $na30 -Destination ($ntap30 + ":" + "/vol/vol4_Mirror1/qtree4")
Remove-NaSnapMirrorSchedule -Controller $na30 -Destination ($ntap30 + ":" + "vol5_Mirror1")
Remove-NaSnapMirrorSchedule -Controller $na30 -Destination ($ntap30 + ":" + "vol6_Mirror1")

Write-Host "====================================================="
Write-Host "Remove volumes on USOXF-NA07 and USEDN-NA30"
Write-Host "====================================================="
#Set-Navol vol1 -Offline -Controller $na07 | Remove-NaVol -Controller $na07 -Confirm:$false
#Set-Navol vol2 -Offline -Controller $na07 | Remove-NaVol -Controller $na07 -Confirm:$false
#Set-Navol vol3 -Offline -Controller $na07 | Remove-NaVol -Controller $na07 -Confirm:$false
#Set-Navol vol4 -Offline -Controller $na07 | Remove-NaVol -Controller $na07 -Confirm:$false
Set-Navol vol5 -Offline -Controller $na07 | Remove-NaVol -Controller $na07 -Confirm:$false
Set-Navol vol6 -Offline -Controller $na07 | Remove-NaVol -Controller $na07 -Confirm:$false
#Set-Navol vol1_Mirror1 -Offline -Controller $na30 | Remove-NaVol -Controller $na30 -Confirm:$false
#Set-Navol vol2_Mirror1 -Offline -Controller $na30 | Remove-NaVol -Controller $na30 -Confirm:$false
#Set-Navol vol3_Mirror1 -Offline -Controller $na30 | Remove-NaVol -Controller $na30 -Confirm:$false
#Set-Navol vol4_Mirror1 -Offline -Controller $na30 | Remove-NaVol -Controller $na30 -Confirm:$false
Set-Navol vol5_Mirror1 -Offline -Controller $na30 | Remove-NaVol -Controller $na30 -Confirm:$false
Set-Navol vol6_Mirror1 -Offline -Controller $na30 | Remove-NaVol -Controller $na30 -Confirm:$false