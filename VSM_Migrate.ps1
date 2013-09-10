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
#param (
#    [string]$workbook = $(throw "-workbook filename.xlsx is required"),
#    [string]$logfile = $(throw "-log logfilename.txt is required"),
#    [bool]$cleanup = $true
# )

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

### Get volumes from the controllers as a test
get-navol -controller $na07
get-navol -controller $na30
get-navol -controller $na50

### Set aggregate variable where new volumes are going to be created
$na07_aggr = "aggr9g"


### Get volumes from na07 except for clones and vol0
$na07_vols = Get-NaVol -Controller $na07 | ? {$_.CloneParent -eq $null} | ? {$_.Name -ne "vol0"} | foreach-object ($vol = $_.Name)

### Test
foreach ($vol in $na01_vols)

### Get vol size
$size = Get-NaVol -Controller $na07 | ? {$_.CloneParent -eq $null} | ? {$_.Name -ne "vol0"} | foreach-object {Get-NavolSize  $_.Name -controller $na07 }

### Get vol fractional reserve
$fracres_percent = Get-NaVol -Controller $na07 | ? {$_.CloneParent -eq $null} | ? {$_.Name -ne "vol0"} | foreach-object {Get-NavolOption $_.Name} | ? {$_.Name -eq "fractional_reserve"} | select-object -Property Value

### Get vol guarantee
$guarantee = Get-NaVol -Controller $na07 | ? {$_.CloneParent -eq $null} | ? {$_.Name -ne "vol0"} | foreach-object {Get-NavolOption $_.Name} | ? {$_.Name -eq "actual_guarantee"} | select-object -Property Value

### Get Snapshot Reserve
$snapres_percentage = Get-NaVol -Controller $na07 | ? {$_.CloneParent -eq $null} | ? {$_.Name -ne "vol0"} | foreach-object {Get-NaSnapshotReserve $_.Name} | select-object -Property Percentage

### Create vols on new destination controller
New-Navol -Controller $na50 -Name $vol -Aggregate $na07_aggr -size $size -SpaceReserve $guarantee -WhatIf
