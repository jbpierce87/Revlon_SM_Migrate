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
Write-Host "Create src vols on USOXF-NA07"
Write-Host "====================================================="
New-NaVol -Controller $na07 -Name vol1 -Aggregate aggr9g -Size 1g
New-NaVol -Controller $na07 -Name vol2 -Aggregate aggr9g -Size 1g
New-NaVol -Controller $na07 -Name vol3 -Aggregate aggr9g -Size 1g
New-NaVol -Controller $na07 -Name vol4 -Aggregate aggr9g -Size 1g
New-NaVol -Controller $na07 -Name vol5 -Aggregate aggr9g -Size 1g
New-NaVol -Controller $na07 -Name vol6 -Aggregate aggr9g -Size 1g

Write-Host "====================================================="
Write-Host "Create dst vols on USEDN-NA30"
Write-Host "====================================================="
New-NaVol -Controller $na30 -Name vol1_Mirror1 -Aggregate aggr9g -Size 1g 
New-NaVol -Controller $na30 -Name vol2_Mirror1 -Aggregate aggr9g -Size 1g 
New-NaVol -Controller $na30 -Name vol3_Mirror1 -Aggregate aggr9g -Size 1g 
New-NaVol -Controller $na30 -Name vol4_Mirror1 -Aggregate aggr9g -Size 1g 
New-NaVol -Controller $na30 -Name vol5_Mirror1 -Aggregate aggr9g -Size 1g 
New-NaVol -Controller $na30 -Name vol6_Mirror1 -Aggregate aggr9g -Size 1g 

Write-Host "====================================================="
Write-Host "Create src qtrees on USOXF-NA07"
Write-Host "====================================================="
New-NaQtree -Controller $na07 -Path /vol/vol3/qtree3
New-NaQtree -Controller $na07 -Path /vol/vol4/qtree4

Write-Host "====================================================="
Write-Host "Set VSM dest vols on USEDN-NA30 to restricted state"
Write-Host "====================================================="
Set-NaVol -Controller $na30 -Name vol1_Mirror1 -Restricted
Set-NaVol -Controller $na30 -Name vol2_Mirror1 -Restricted
Set-NaVol -Controller $na30 -Name vol5_Mirror1 -Restricted
Set-NaVol -Controller $na30 -Name vol6_Mirror1 -Restricted

$src1 = $ntap07 + ":" + "vol1"
$src2 = $ntap07 + ":" + "vol2"
$src3 = $ntap07 + ":" + "/vol/vol3/qtree3"
$src4 = $ntap07 + ":" + "/vol/vol4/qtree4"
$src5 = $ntap07 + ":" + "vol5"
$src6 = $ntap07 + ":" + "vol6"
$dst1 = $ntap30 + ":" + "vol1_Mirror1"
$dst2 = $ntap30 + ":" + "vol2_Mirror1"
$dst3 = $ntap30 + ":" + "/vol/vol3_Mirror1/qtree3"
$dst4 = $ntap30 + ":" + "/vol/vol4_Mirror1/qtree4"
$dst5 = $ntap30 + ":" + "vol5_Mirror1"
$dst6 = $ntap30 + ":" + "vol6_Mirror1"

Write-Host "====================================================="
Write-Host "Initialize Mirrors"
Write-Host "====================================================="
Invoke-NaSnapmirrorInitialize -Source $src1 -Destination $dst1 -Controller $na30
Invoke-NaSnapmirrorInitialize -Source $src2 -Destination $dst2 -Controller $na30
Invoke-NaSnapmirrorInitialize -Source $src3 -Destination $dst3 -Controller $na30
Invoke-NaSnapmirrorInitialize -Source $src4 -Destination $dst4 -Controller $na30
# Can only have 4 tranfers in progress with a VSIM
Write-Host "** Sleeping 30 seconds **"
Start-Sleep -s 30
Invoke-NaSnapmirrorInitialize -Source $src5 -Destination $dst5 -Controller $na30
Invoke-NaSnapmirrorInitialize -Source $src6 -Destination $dst6 -Controller $na30

Write-Host "====================================================="
Write-Host "Setup Snapmirror Schedules"
Write-Host "====================================================="
Set-NaSnapmirrorSchedule -Source $src1 -Destination $dst1 -Minutes 5 -Hours 1-24/2 -DaysOfMonth * -DaysOfWeek * -Controller $na30
Set-NaSnapmirrorSchedule -Source $src2 -Destination $dst2 -Minutes 10 -Hours 1-24/2 -DaysOfMonth * -DaysOfWeek * -Controller $na30
Set-NaSnapmirrorSchedule -Source $src3 -Destination $dst3 -Minutes 15 -Hours 1-24/2 -DaysOfMonth * -DaysOfWeek * -Controller $na30
Set-NaSnapmirrorSchedule -Source $src4 -Destination $dst4 -Minutes 20 -Hours 1-24/2 -DaysOfMonth * -DaysOfWeek * -Controller $na30
Set-NaSnapmirrorSchedule -Source $src5 -Destination $dst5 -Minutes 25 -Hours 1-24/2 -DaysOfMonth * -DaysOfWeek * -Controller $na30
Set-NaSnapmirrorSchedule -Source $src6 -Destination $dst6 -Minutes 30 -Hours 1-24/2 -DaysOfMonth * -DaysOfWeek * -Controller $na30
