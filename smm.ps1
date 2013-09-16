<#
.SYNOPSIS
  Migrates NetApp 7-mode VSM and QSM destinations from one filer to another

.DESCRIPTION
  Reads an Excel Configuration Workbook for a list of VSM and QSM destinations
  and migrates them to a new 7-mode destination filer 

.NOTES
  File: VSM_Migrate.ps1
  Requires: PowerShell V2, Data ONTAP Powershell Toolkit v2.x

.EXAMPLE
  .\VSM_Migrate.ps1 -workbook build.xlsx -log log.txt

  Fill in example doc  

.EXAMPLE
  .\VSM_Migrate.ps1 -workbook build.xlsx -log log.txt -cleanup $false
  
  Fill in example doc  

.PARAMETER workbook

.PARAMETER logfile

.PARAMETER cleanup
#>
param (
    [string]$csvfile = $(throw "-csv filename.csv is required"),
    [string]$logfile = $(throw "-log logname.txt is required"),
    [bool]$cleanup = $true
)
import-module DataONTAP

function checkparams() {
}

### Controller Login Variables
$ntap07 = "usoxf-na07"
$ntap30 = "usedn-na30"
$ntap50 = "usedn-na50"

$ntapuser = "root"
$ntappw = "AcmeL4b#"

### Convert Password to plain text
$pw = convertto-securestring $ntappw -asplaintext -force
$cred = new-object -typename system.management.automation.pscredential -argumentlist $ntapuser,$pw

### Connect to the controllers
#$na07 = Connect-NaController $ntap07 -Credential $cred -https
#$na30 = Connect-NaController $ntap30 -Credential $cred -https
#$na50 = Connect-NaController $ntap50 -Credential $cred -https

#$sourcefile = resolve-path $csvfile
$csvobjects = Import-Csv -Path (resolve-path $csvfile).Path

#$sources = @()
$sources += ($csvobjects | foreach-object {$_.SRC}) | select -uniq
foreach ($src in $sources) {
    "src: " + $src
    $dynvars += New-Variable -Name "var$src" -Value $src
}
write-host "=========== dynvars ============"
$dynvars
#$na30 = Connect-NaController $ntap30 -Credential $cred -https
#$na50 = Connect-NaController $ntap50 -Credential $cred -https
$csvobjects | foreach-object {
#    $_.SRC
#    $_.SRCVOL
#    $_.ODST
#    $_.ODSTVOL
#    $_.NDST
#    $_.NDSTVOL
#    $_.NDSTAGGR
}
