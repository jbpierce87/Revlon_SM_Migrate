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

New-NaVol -Controller $na07 -Name vol1 -Aggregate aggr9g -Size 1g
New-NaVol -Controller $na07 -Name vol2 -Aggregate aggr9g -Size 1g
New-NaVol -Controller $na07 -Name vol3 -Aggregate aggr9g -Size 1g
New-NaVol -Controller $na07 -Name vol4 -Aggregate aggr9g -Size 1g

New-NaVol -Controller $na30 -Name vol1_Mirror1 -Aggregate aggr9g -Size 1g 
New-NaVol -Controller $na30 -Name vol2_Mirror1 -Aggregate aggr9g -Size 1g 
New-NaVol -Controller $na30 -Name vol3_Mirror1 -Aggregate aggr9g -Size 1g 
New-NaVol -Controller $na30 -Name vol4_Mirror1 -Aggregate aggr9g -Size 1g 

Set-NaVol -Controller $na30 -Name vol1_Mirror1 -Restricted
Set-NaVol -Controller $na30 -Name vol2_Mirror1 -Restricted
Set-NaVol -Controller $na30 -Name vol3_Mirror1 -Restricted
Set-NaVol -Controller $na30 -Name vol4_Mirror1 -Restricted

$src1 = $ntap07 + ":" + "vol1"
$src2 = $ntap07 + ":" + "vol2"
$src3 = $ntap07 + ":" + "vol3"
$src4 = $ntap07 + ":" + "vol4"
$dst1 = $ntap30 + ":" + "vol1_Mirror1"
$dst2 = $ntap30 + ":" + "vol2_Mirror1"
$dst3 = $ntap30 + ":" + "vol3_Mirror1"
$dst4 = $ntap30 + ":" + "vol4_Mirror1"

Invoke-NaSnapmirrorInitialize -Source $src1 -Destination $dst1 -Controller $na30
Invoke-NaSnapmirrorInitialize -Source $src2 -Destination $dst2 -Controller $na30
Invoke-NaSnapmirrorInitialize -Source $src3 -Destination $dst3 -Controller $na30
Invoke-NaSnapmirrorInitialize -Source $src4 -Destination $dst4 -Controller $na30

