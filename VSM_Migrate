import-module DataONTAP

### Controller Login Variables

$ntap30 = "usedn-na30"
$ntap50 = "usedn-na50"
$ntap07 = "usoxf-na07"

$password1 = "AcmeL4b#"
$password2 = "AcmeL4b#"
$password3 = "AcmeL4b#"

$ntapuser = "root"
$ntappw = "$password1"
$ntappw2 = "$password2"
$ntappw3 = "$password3"

### usedn-na30 Convert Password to plain text
$pw1 = convertto-securestring $ntappw -asplaintext -force
$cred1 = new-object -typename system.management.automation.pscredential -argumentlist $ntapuser,$pw1

### usedn-na50 Convert Password to plain text
$pw2 = convertto-securestring $ntappw2 -asplaintext -force
$cred2 = new-object -typename system.management.automation.pscredential -argumentlist $ntapuser,$pw2

### usoxf-na07 Convert Password to plain text
$pw3 = convertto-securestring $ntappw3 -asplaintext -force
$cred3 = new-object -typename system.management.automation.pscredential -argumentlist $ntapuser,$pw3

### Connect to the controllers 
$na30 = Connect-NaController $ntap30 -Credential $cred1 -https
$na50 = Connect-NaController $ntap50 -Credential $cred2 -https
$na07 = Connect-NaController $ntap07 -Credential $cred3 -https

###Get volumes on na50 that are restricted
$na50_vols get-navol -controller $na50 | ? ($vol.state -eq "restricted") 

###Create new snapmirror destination volumes from current destinations on usedn-na50 to usoxf-na07
$na50_vols get-navol -controller $na50 | ? ($vol.state -eq "restricted")  

###Initialize relationship between usedn-na50 and usoxf-na07 

Get-NaSnapmirror | Invoke-NaSnapmirrorUpdate
