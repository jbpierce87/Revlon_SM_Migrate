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

$ntap07 = "usoxf-na07"
$ntap30 = "usedn-na30"
$ntap50 = "usedn-na50"

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
$na50_aggr = "aggr3_3t"


### Get volumes from na30 except for clones and vol0
$na30_vols = Get-NaVol -Controller $na30 | ? {$_.CloneParent -eq $null} | ? {$_.Name -ne "vol0"} 

### Get volume properties for each volume
foreach ($vol in $na30_vols) {

    $size = Get-NaVolSize -Controller $na30 -Name $vol.Name
    $guarantee = ((Get-NaVolOption -controller $na30 -Name $vol.Name) | ? { $_.Name -eq "actual_guarantee" }).Value
    $fracres_percent = ((Get-NaVolOption -Controller $na30 -Name $vol.Name) | ? { $_.Name -eq "fractional_reserve" }).Value
    $snapres_percent = (Get-NaSnapshotReserve -Controller $na30 -TargetName $vol.Name).Percentage


### Create the new volume and set guarantees appropriately on na50
    New-NaVol -Controller $na50 -Name $vol.Name -Aggregate $na50_aggr -size $size.VolumeSize -SpaceReserve $guarantee }

### Get Snapmirror schedules from na30 and assign variables
$snapschedna30 = Get-NaSnapmirrorSchedule -Controller $na30 
$snapschednadest30 = Get-NaSnapmirrorSchedule -Controller $na30 | select-object Destination | out-string
$snapdestna50 = get-navol -Controller $na50 | ? {$_.CloneParent -eq $null} | ? {$_.Name -ne "vol0"} | foreach-object { 
    $_.Name 
    $destna50 = "usedn-na50:/vol/" + $_.Name } 

foreach ($snapsource in $snapschedna30) {

    $snapsourcena30 = $snapschedna30 | select-object Destination | out-string
    $snaprate = ($snapschedna30 | select-object MaxRate).Value | out-string
    $snapminutes = $snapschedna30 | select-object Minutes | out-string
    $snaphours = $snapschedna30 | select-object Hours | out-string
    $snapdaysofweek = $snapschedna30 | select-object DaysOfWeek | out-string

### Having trouble with daysofmonth converting to string for input as variable ******
    $snapdaysofmonth = "*"

### Set Snapmirror schedule on new destination na07
    set-nasnapmirrorschedule -source $snapsourcena30 -Destination $destna50 -Minutes $snapminutes -Hours $snaphours -DaysOfWeek $snapdaysofweek -DaysOfMonth * }

### Initialize SnapMirror from old destination (na30) to new destination (na50)
$snapmirrordestna50 = Get-NaSnapmirrorSchedule -Controller $na50 | select-object Destination | out-string

foreach ($snapsource2 in $snapmirrordestna50) {

    $snapsourcena30 = $snapschedna50 | select-object Destination | out-string
    Invoke-NaSnapmirrorInitialize -source $snapsourcena30 -Destination $destna50 }


