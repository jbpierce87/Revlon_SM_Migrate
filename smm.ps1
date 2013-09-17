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
    [ValidateSet("seed","update","cutover","none")][string]$mode = "none",
    [bool]$cleanup = $true
)

import-module DataONTAP

function msg($message) {
    Write-Host ""
    Write-Host "====================================================="
    Write-Host "$message"
    Write-Host "====================================================="
}

$TranscriptFile = $logfile 
start-transcript $TranscriptFile -noclobber

### Controller Login Variables
$ntap07 = "usoxf-na07"
$ntap30 = "usedn-na30"
$ntap50 = "usedn-na50"

$ntapuser = "root"
$ntappw = "AcmeL4b#"

### Convert Password to plain text
$pw = convertto-securestring $ntappw -asplaintext -force
$cred = new-object -typename system.management.automation.pscredential -argumentlist $ntapuser,$pw

### Slurp in the CSV file with our input 
$csvobjects = Import-Csv -Path (resolve-path $csvfile).Path

#$sources += ($csvobjects | foreach-object {$_.SRC}) | select -uniq
#for ($i = 0; $i -le $sources.Length; $i++) {
#    New-Variable -Name "srcStr$i" -Value $sources[$i]
#    New-Variable -Name "srcNodeObj$i" -Value $sources[$i]
#}

### Connect to our source, old destination, and new destination controllers
$src_node = Connect-NaController $csvobjects[0].SRCNODE -Credential $cred -https
$dstold_Node = Connect-NaController $csvobjects[0].ODSTNODE -Credential $cred -https
$dstnew_Node = Connect-NaController $csvobjects[0].NDSTNODE -Credential $cred -https

# $_.SRCNODE $_.SRCPATH $_.ODSTNODE $_.ODSTPATH $_.NDSTNODE $_.NDSTPATH $_.NDSTAGGR
switch ($mode) {
    "seed" {
        $csvobjects | foreach-object {
            if ($_.SRCPATH -notmatch "^/vol/") {
                # VSM relationship
                msg ("Seeding VSM source: " + $_.ODSTNODE + ":" + $_.ODSTPATH)
                $src = Get-Navol -Controller $dstold_node -Name $_.ODSTPATH
                if ($src.State -eq "online") {
                    $size = Get-NaVolSize -Controller $dstold_node -Name $_.ODSTPATH
                    $guarantee = ((Get-NaVolOption -Controller $dstold_node -Name $src.Name) | ? { $_.Name -eq "actual_guarantee" }).Value
                    msg ("create vol: " + $_.NDSTPATH)
                    New-NaVol -Controller $dstnew_Node -Name $_.NDSTPATH -Aggregate $_.NDSTAGGR -size $size.VolumeSize -SpaceReserve $guarantee
                    msg ("restrict vol: " + $_.NDSTPATH)
                    Set-NaVol -Controller $dstnew_Node -Name $_.NDSTPATH -Restricted
                    $tsrc = $dstold_Node.Name + ":" + $_.NDSTPATH 
                    $tdst = $dstnew_Node.Name + ":" + $_.NDSTPATH 
                    Invoke-NaSnapmirrorInitialize -Source $tsrc -Destination $tdst -Controller $dstnew_Node
                } 
            } elseif ($_.SRCPATH -match "^/vol/") {
                # QSM relationship
                msg ("Seeding QSM source: " + $_.ODSTNODE + ":" + $_.ODSTPATH)
            }
        }
    }

    "update" {
        $csvobjects | foreach-object {
            if ($_.SRCPATH -notmatch "^/vol/") {
                # VSM relationship
                msg ("Updating VSM source: " + $_.ODSTNODE + ":" + $_.ODSTPATH + " to: " + $_.NDSTNODE + ":" + $_.NDSTPATH)
                $mirrored = Test-NaSnapmirrorVolume -Controller $dstold_node -Volume $_.ODSTPATH 
                if ( ($mirrored.IsDestination) -and (!($mirrored.IsTransferBroken)) ) {
                    msg ("update na30: " + $_.ODSTPATH + "To na50: " + $_.NDSTPATH)
                    $tsrc = $dstold_Node.Name + ":" + $_.NDSTPATH 
                    $tdst = $dstnew_Node.Name + ":" + $_.NDSTPATH 
                    Invoke-NaSnapmirrorUpdate -Source $tsrc -Destination $tdst -Controller $dstnew_Node
                } 

            } elseif ($_.SRCPATH -match "^/vol/") {
                # QSM relationship
                msg ("Working with QSM source: " + $_.ODSTNODE + ":" + $_.ODSTPATH)
            }
        }
    }

    "cutover" {
        $csvobjects | foreach-object {
            if ($_.SRCPATH -notmatch "^/vol/") {
                # VSM relationship
                msg ("Cutting over VSM source: " + $_.ODSTNODE + ":" + $_.ODSTPATH)
                $odst = Get-Navol -Controller $dstold_node -Name $_.ODSTPATH
                $ndst = Get-Navol -Controller $dstold_node -Name $_.ODSTPATH
                
            } elseif ($_.SRCPATH -match "^/vol/") {
                # QSM relationship
                msg ("Working with QSM source: " + $_.ODSTNODE + ":" + $_.ODSTPATH)
            }
        }
    }

    "none" {
        Write-Host "Help is required"
        break
    }
}

stop-transcript
