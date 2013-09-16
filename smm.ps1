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
    [ValidateSet("seed","update","cutover")][string]$mode = "none",
    [bool]$cleanup = $true
)

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

### Connect to the source controllers

$csvobjects = Import-Csv -Path (resolve-path $csvfile).Path

#$sources += ($csvobjects | foreach-object {$_.SRC}) | select -uniq
#for ($i = 0; $i -le $sources.Length; $i++) {
#    New-Variable -Name "srcStr$i" -Value $sources[$i]
#    New-Variable -Name "srcNodeObj$i" -Value $sources[$i]
#}

### Connect to our source, old destination, and new desitnation controllers
$src_node = Connect-NaController $csvobjects[0].SRCNODE -Credential $cred -https
$dstold_Node = Connect-NaController $csvobjects[0].ODSTNODE -Credential $cred -https
$dstnew_Node = Connect-NaController $csvobjects[0].NDSTNODE -Credential $cred -https

# $_.SRCNODE $_.SRCPATH $_.ODSTNODE $_.ODSTPATH $_.NDSTNODE $_.NDSTPATH $_.NDSTAGGR
switch ($mode) {
    "seed" {
        $csvobjects | foreach-object {
            if ($_.SRCPATH -notmatch "^/vol/") {
                # VSM relationship
                write-host "Working with a VSM source"
                $src = Get-Navol $_.ODSTPATH -Controller $dstold_node
                if ($src.State -eq "online") {
                    $size = Get-NaVolSize -Controller $dstold_node -Name $_.ODSTPATH
                    $guarantee = ((Get-NaVolOption -Controller $dstold_node -Name $src.Name) | ? { $_.Name -eq "actual_guarantee" }).Value
                    write-host ("creating new dst volume " + $_.NDSTPATH)
                } 
            } elseif ($_.SRCPATH -match "^/vol/") {
                # QSM relationship
                write-host "Working with a QSM source"
            }
        }
    }

    "update" {
        $csvobjects | foreach-object {
        }
    }

    "cutover" {
        $csvobjects | foreach-object {
        }
    }

    "none" {
        Write-Host "Help is required"
        break
    }
}
