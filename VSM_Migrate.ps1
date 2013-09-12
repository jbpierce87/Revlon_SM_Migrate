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

### Get Snapmirror schedules from na30 and assign variables
$snapschedna30 = Get-NaSnapmirrorSchedule -Controller $na30 | select-object Source | out-string
$snapdestna50 = get-navol -Controller $na50 | ? {$_.CloneParent -eq $null} | ? {$_.Name -ne "vol0"} | foreach-object { 
    $_.Name 
    $destna50 = "usoxf-na07:/vol/" + $_.Name } 

foreach ($snapsource in $snapschedna30) {

    $snapsourcena30 = $snapschedna30 | select-object Destination | out-string
    $snaprate = ($snapschedna30 | select-object MaxRate).Value | out-string
    $snapminutes = $snapschedna30 | select-object Minutes | out-string
    $snaphours = $snapschedna30 | select-object Hours | out-string
    # $snapdaysofweek = $snapschedna30 | select-object DaysOfWeek | out-string

### Having trouble with daysofmonth converting to string for input as variable ******
    $snapdaysofmonth = "*"

### Create the new volume and set guarantees appropriately on na50
    set-nasnapmirrorschedule -source $snapsourcena30 -Destination $destna50 -Minutes $snapminutes -Hours $snaphours -DaysOfWeek $snapdaysofweek -DaysOfMonth * }

