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
$na30 = Connect-NaController $ntap30 -Credential $cred -https
$na50 = Connect-NaController $ntap50 -Credential $cred -https
$na07 = Connect-NaController $ntap07 -Credential $cred -https

###Get volumes on na50 that are restricted
$na50_vols get-navol -controller $na50 | ? ($vol.state -eq "restricted") 

###Create new snapmirror destination volumes from current destinations on usedn-na50 to usoxf-na07
$na50_vols get-navol -controller $na50 | ? ($vol.state -eq "restricted")  

###Initialize relationship between usedn-na50 and usoxf-na07 

#Get-NaSnapmirror | Invoke-NaSnapmirrorUpdate
