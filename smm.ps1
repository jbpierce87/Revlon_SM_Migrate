<#
.SYNOPSIS
  Migrates NetApp 7-mode VSM and QSM destinations from one filer to another

.DESCRIPTION
  Reads a CSV file for a list of VSM and QSM destinations and migrates them to a new 7-mode destination filer

.NOTES
  File: smm.ps1
  Requires: PowerShell V2, Data ONTAP Powershell Toolkit v2.x or above
  Input csv file format:
            SourceController,SourchPath, OldDstController, OldDstPath, NewDstController, NewDstPath, NewDstPathAggr
  Sample Input File:
            src_filer,vol1,odst_filer,vol1_mirror,ndst_filer,vol1_mirror,aggr1
            src_filer,vol2,odst_filer,vol2_mirror,ndst_filer,vol2_mirror,aggr2

            The file above would migrate VSM destination volumes vol1_mirror and vol2_mirror from odst_filer to
            ndst_filer.  vol1_mirror on ndst_filer would be placed on aggr1 and vol2_mirror on ndst_filer would
            be placed on aggr2.  vol1_mirror and vol2_mirror on ndst_filer will be created by the script and have
            their volume guarantees set to whatever the guarantees are set to on odst_filer.

.EXAMPLE
  .\smm.ps1 -mode seed -csv input.csv -log seedlog.txt

  Fill in example doc  

.EXAMPLE
  .\smm.ps1 -mode update -csv input.csv -log updatelog.txt
  
  Fill in example doc  

.EXAMPLE
  .\smm.ps1 -mode cutover -csv input.csv -log cutoverlog.txt
  
  Fill in example doc  

.PARAMETER csv

.PARAMETER log

.PARAMETER mode
#>
#
# Pull in our parameters from the command line
# -csv and -log are required.  -cleanup reserved for future use.
param (
    [string]$csvfile = $(throw "-csv filename.csv is required"),
    [string]$logfile = $(throw "-log logname.txt is required"),
    [ValidateSet("seed","update","cutover","status","release","none")][string]$mode = "none",
    [bool]$cleanup = $true
)

# Import the ONTAP PS Module
Import-Module DataONTAP

# Functions
Function header($message) {
    Write-Host ""
    Write-Host "====================================================="
    Write-Host "$message"
    Write-Host "====================================================="
}

$TranscriptFile = $logfile 
Start-Transcript $TranscriptFile

# User and password for NetApp controllers
# Modifications required if the controllers all use different credentials
$ntapuser = "root"
$ntappw = "AcmeL4b#"

# Convert password from plain text to a secure string
$pw = convertto-securestring $ntappw -asplaintext -force
$cred = new-object -typename system.management.automation.pscredential -argumentlist $ntapuser,$pw

# Slurp in the CSV file with our input 
# Input file format is: SRCNODE,SRCPATH,ODSTNODE,ODSTPATH,NDSTNODE,NDSTPATH,NDSTAGGR
$csvobjects = Import-Csv -Path (resolve-path $csvfile).Path

#$sources += ($csvobjects | foreach-object {$_.SRC}) | select -uniq
#for ($i = 0; $i -le $sources.Length; $i++) {
#    New-Variable -Name "srcStr$i" -Value $sources[$i]
#    New-Variable -Name "srcNode$i" -Value $sources[$i]
#}

# Connect to our source, old destination, and new destination controllers
$src_node = Connect-NaController $csvobjects[0].SRCNODE -Credential $cred -https
$dstold_node = Connect-NaController $csvobjects[0].ODSTNODE -Credential $cred -https
$dstnew_node = Connect-NaController $csvobjects[0].NDSTNODE -Credential $cred -https

# Set timeouts high to deal with "pokey" controllers (ie na30 in our case)
$src_node.TimeoutMsec=180000
$dstold_node.TimeoutMsec=180000
$dstnew_node.TimeoutMsec=180000

# Main 
switch ($mode) {
    # Initialize the second hop of the cascade 
    "seed" {
        $csvobjects | foreach-object {
            if ($_.SRCPATH -notmatch "^/vol/") {
                # VSM relationship
                header ("Seed VSM source: " + $_.ODSTNODE + ":" + $_.ODSTPATH)
                $src = Get-Navol -Controller $dstold_node -Name $_.ODSTPATH
                if ($src.State -eq "online") {
                    $size = Get-NaVolSize -Controller $dstold_node -Name $_.ODSTPATH
                    $guarantee = ((Get-NaVolOption -Controller $dstold_node -Name $src.Name) | ? { $_.Name -eq "actual_guarantee" }).Value
                    Write-Host ("create vol: " + $_.NDSTPATH)
                    New-NaVol -Controller $dstnew_Node -Name $_.NDSTPATH -Aggregate $_.NDSTAGGR -size $size.VolumeSize -SpaceReserve $guarantee
                    Write-Host ("restrict vol: " + $_.NDSTPATH)
                    Set-NaVol -Controller $dstnew_Node -Name $_.NDSTPATH -Restricted
                    $tsrc = $dstold_Node.Name + ":" + $_.ODSTPATH 
                    $tdst = $dstnew_Node.Name + ":" + $_.NDSTPATH 
                    Invoke-NaSnapmirrorInitialize -Source $tsrc -Destination $tdst -Controller $dstnew_Node
                } else {
                    Write-Host ("Volume " + $src.Name + " not online.  Skipping!")
                }
            } elseif ($_.SRCPATH -match "^/vol/") {
                # QSM relationship
                header ("Seed QSM source: " + $_.ODSTNODE + ":" + $_.ODSTPATH)
            }
        }
    }

    # Get status for both hops in our cascade
    "status" {
        $csvobjects | foreach-object {
            if ($_.SRCPATH -notmatch "^/vol/") {
                # VSM relationship
                $src = $src_Node.Name + ":" + $_.SRCPATH
                $odst = $dstold_Node.Name + ":" + $_.ODSTPATH 
                $ndst = $dstnew_Node.Name + ":" + $_.NDSTPATH
                header ("Status for VSM relationships: " + $_.ODSTNODE + ":" + $_.ODSTPATH)
                Get-NaSnapmirror -Controller $dstold_node -Location $src
                Get-NaSnapmirror -Controller $dstnew_node -Location $ndst
            } elseif ($_.SRCPATH -match "^/vol/") {
                # QSM relationship
                header ("Status QSM source: " + $_.ODSTNODE + ":" + $_.ODSTPATH)
            }
        }
    }

    # Update the second leg of the cascade (if needed)
    "update" {
        $csvobjects | foreach-object {
            if ($_.SRCPATH -notmatch "^/vol/") {
                # VSM relationship
                header ("Update VSM source: " + $_.ODSTNODE + ":" + $_.ODSTPATH + " to: " + $_.NDSTNODE + ":" + $_.NDSTPATH)
                $src = $src_node.Name + ":" + $_.SRCPATH
                $odst = $dstold_node.Name + ":" + $_.ODSTPATH
                $ndst = $dstnew_node.Name + ":" + $_.NDSTPATH
                $mirrored = Test-NaSnapmirrorVolume -Controller $dstold_node -Volume $_.ODSTPATH 
                if ( ($mirrored.IsDestination) -and (!($mirrored.IsTransferBroken)) ) {
                    $ostate = Get-NaSnapmirror -Controller $dstold_node -Location $src 
                    $nstate = Get-NaSnapmirror -Controller $dstnew_node -Location $ndst
                    $olag = $('{0:N2}' -f $ostate.LagTimeTS.TotalHours)
                    $nlag = $('{0:N2}' -f $nstate.LagTimeTS.TotalHours)
                    if ( $olag -lt $nlag ) {
                        Write-Host ("First leg is more up to date than the second leg.  Updating.")
                        Write-Host ("update na30: " + $_.ODSTPATH + "to na50: " + $_.NDSTPATH)
                        $tsrc = $dstold_Node.Name + ":" + $_.NDSTPATH 
                        $tdst = $dstnew_Node.Name + ":" + $_.NDSTPATH 
                        Invoke-NaSnapmirrorUpdate -Source $tsrc -Destination $tdst -Controller $dstnew_Node
                    } elseif ( $olag -eq $nlag ) {
                        Write-Host ("na07:" + $_.SRCPATH + " -->> " + "na30: " + $_.ODSTPATH + " -->> na50: " + $_.NDSTPATH)
                        Write-Host ("Cascade is up to date.  No update necessary.")
                    } else {
                        Write-Host ("Oh crap we should never get here")
                    }
                } else {
                    Write-Host ($_ODSTNODE + ":" + $_.ODSTPATH + " is not a snapmirror destination or transfers to it are broken. Skipping!")
                } 
            } elseif ($_.SRCPATH -match "^/vol/") {
                # QSM relationship
                header ("Update QSM source: " + $_.ODSTNODE + ":" + $_.ODSTPATH)
            }
        }
    }

    # Cut the VSM destinations over to the new destination system.  Cutover breaks the original mirrors and updates the
    # new destination using the source but doesn't do anything destructive otherwise.  We can still recover if need be.
    "cutover" {
        $csvobjects | foreach-object {
            if ($_.SRCPATH -notmatch "^/vol/") {
                # We're dealing with a VSM relationship
                header ("Cut over VSM source: " + $_.ODSTNODE + ":" + $_.ODSTPATH)
                $src = $src_node.Name + ":" + $_.SRCPATH
                $odst = $dstold_node.Name + ":" + $_.ODSTPATH
                $ndst = $dstnew_node.Name + ":" + $_.NDSTPATH

                # It would be easier to just deal with the middle controller in the cascade
                # since it has state for both relationships.  However, in Revlon's case
                # it's easier to deal with the source and new destination systems because they
                # are less likely to timeout than the old destination (ie na30 is pokey)
                # Lag times are time/NTP dependent.  Make sure time is synced on src/odst/ndst systems.
                $ostate = Get-NaSnapmirror -Controller $dstold_node -Location $src
                $nstate = Get-NaSnapmirror -Controller $dstnew_node -Location $ndst

                # We'll convert and round to get rid of seconds for lag time comparison. A few seconds off won't kill us.
                $olag = $('{0:N2}' -f $ostate.LagTimeTS.TotalHours)
                $nlag = $('{0:N2}' -f $nstate.LagTimeTS.TotalHours)

                # If the lag on the second hop is higher, we need to update that leg before we cutvoer.
                if ( $olag -lt $nlag ) {
                    Write-Host ($src + " -->> " + $odst + " is more up to date than " + $odst + " -->> " + $ndst)
                    Invoke-NaSnapmirrorUpdate -Controller $dstnew_node -Source $odst -Destination $ndst
                    $state = Get-NaSnapmirror -Controller $dstnew_node -Location $ndst
                    Write-Host ("Updating " + $odst + " -->> " + $ndst + " BLOCKING UNTIL IT COMPLETES")
                    do {
                        $state = Get-NaSnapmirror -Controller $dstnew_node -Location $ndst
                        start-sleep -s 30 
                    } 
                    while ($state.Status -ne "idle")
                }
                
                $ostate = Get-NaSnapmirror -Controller $dstold_node -Location $src
                $nstate = Get-NaSnapmirror -Controller $dstnew_node -Location $ndst
                $olag = $('{0:N2}' -f $ostate.LagTimeTS.TotalHours)
                $nlag = $('{0:N2}' -f $nstate.LagTimeTS.TotalHours)

                if ( $olag -eq $nlag ) {
                    Write-Host ("** Lag Times Are Equal - Cutting Over **")
                    Write-Host ("Setting snapmirror schedules on new destination based on old destination") 
#                    Get-NaSnapMirrorSchedule -Controller $dstold_node -Destination $odst | Set-NaSnapMirrorSchedule -Controller $dstnew_node -Destination $ndst
                    # Note: code below needs updates if preserving options like kbs=2000 is required.  It wasn't in my case so I didn't bother coding it.
                    $schedule = Get-NaSnapMirrorSchedule -Controller $dstold_node -Destination $odst 
                    Set-NaSnapMirrorSchedule    -Controller $dstnew_node `
                                                -Source $src `
                                                -Destination $ndst `
                                                -Hours $schedule.Hours `
                                                -Minutes $schedule.Minutes `
                                                -DaysOfWeek $schedule.DaysOfWeek `
                                                -DaysOfMonth $schedule.DaysOfMonth 
                    Remove-NaSnapMirrorSchedule -Controller $dstold_node -Destination $odst
                    Write-Host ($dstold_node.Name + ": snapmirror break " + $odst ) 
                    Invoke-NaSnapmirrorBreak -Controller $dstold_node -Destination $odst -Confirm:$false
                    Write-Host ($dstnew_node.Name + ": snapmirror update " + $ndst ) 
                    Invoke-NaSnapmirrorUpdate -Controller $dstnew_node -Source $src -Destination $ndst
                } else {
                    Write-Host ("Oh crap")
                }
            } elseif ($_.SRCPATH -match "^/vol/") {
                # QSM relationship
                header ("Cut over QSM source: " + $_.ODSTNODE + ":" + $_.ODSTPATH)
            }
        }
    }

    # Release is the point of no return.  Once we've run this, base snaps for the original relationships are destroyed
    # using snapmirror release on the sources and snap delete on the destinations.
    "release" {
        $csvobjects | foreach-object {
            if ($_.SRCPATH -notmatch "^/vol/") {
                # VSM relationship
                $src = $src_Node.Name + ":" + $_.SRCPATH
                $odst = $dstold_Node.Name + ":" + $_.ODSTPATH 
                $ndst = $dstnew_Node.Name + ":" + $_.NDSTPATH
                header ("Release for VSM source: " + $src + " " + $odst)
                Invoke-NaSnapmirrorRelease -Controller $src_node -Source $src -Destination $odst -Confirm:$false
                header ("Release for VSM source: " + $odst + " " + $ndst)
                Invoke-NaSnapmirrorRelease -Controller $dstold_node -Source $odst -Destination $ndst -Confirm:$false
                $basesnap = (Get-NaSnapmirror -Controller $dstold_node -Location $odst).BaseSnapshot 
                header ($dstold_node.Name + " delete base snap: " + $basesnap + " on volume: " + $_.ODSTPATH)
                Remove-NaSnapshot -Controller $dstold_node -TargetName $_.ODSTPATH -Snapname $basesnap -Confirm:$false
            } elseif ($_.SRCPATH -match "^/vol/") {
                # QSM relationship
                header ("Release QSM source: " + $_.ODSTNODE + ":" + $_.ODSTPATH)
            }
        }
    }

    # Default mode.  Need to fill out the script help.
    "none" {
        Write-Host "Help is required"
        break
    }
}

Stop-Transcript
