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

msg "Create src vols on USOXF-NA07"
New-NaVol -Controller $na07 -Name vol5 -Aggregate aggr9g -Size 1g -SpaceReserve none 
New-NaVol -Controller $na07 -Name vol6 -Aggregate aggr9g -Size 1g -SpaceReserve volume
Set-NaSnapshotReserve -Controller $na07 -TargetName vol5 -Percentage 10 
Set-NaSnapshotReserve -Controller $na07 -TargetName vol6 -Percentage 30 
Set-NaVolOption -Controller $na07 -Name vol5 -Key create_ucode -Value on
Set-NaVolOption -Controller $na07 -Name vol5 -Key convert_ucode -Value on
Set-NaVolOption -Controller $na07 -Name vol6 -Key create_ucode -Value off 
Set-NaVolOption -Controller $na07 -Name vol6 -Key convert_ucode -Value off 

msg "Create dst vols on USEDN-NA30"
New-NaVol -Controller $na30 -Name vol5_Mirror1 -Aggregate aggr9g -Size 1g -SpaceReserve none
New-NaVol -Controller $na30 -Name vol6_Mirror1 -Aggregate aggr9g -Size 1g -SpaceReserve volume 

#Write-Host "====================================================="
#Write-Host "Create src qtrees on USOXF-NA07"
#Write-Host "====================================================="
#New-NaQtree -Controller $na07 -Path /vol/vol3/qtree3
#New-NaQtree -Controller $na07 -Path /vol/vol4/qtree4

msg "Set dest vols on USEDN-NA30 to restricted state"
Set-NaVol -Controller $na30 -Name vol5_Mirror1 -Restricted
Set-NaVol -Controller $na30 -Name vol6_Mirror1 -Restricted

$src5 = $ntap07 + ":" + "vol5"
$src6 = $ntap07 + ":" + "vol6"
$dst5 = $ntap30 + ":" + "vol5_Mirror1"
$dst6 = $ntap30 + ":" + "vol6_Mirror1"

msg "Initialize Mirrors"
Invoke-NaSnapmirrorInitialize -Source $src5 -Destination $dst5 -Controller $na30
Invoke-NaSnapmirrorInitialize -Source $src6 -Destination $dst6 -Controller $na30

msg "Setup Snapmirror Schedules"
Set-NaSnapmirrorSchedule -Source $src5 -Destination $dst5 -Minutes 25 -Hours 1-24/2 -DaysOfMonth * -DaysOfWeek * -Controller $na30
Set-NaSnapmirrorSchedule -Source $src6 -Destination $dst6 -Minutes 30 -Hours 1-24/2 -DaysOfMonth * -DaysOfWeek * -Controller $na30
