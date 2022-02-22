# PowerShell code
 
########################################################
# Parameters
########################################################
[CmdletBinding()]
param(
    [Parameter(Mandatory=$True,Position=0)]
    [ValidateSet('start','pause')]
    [string]$AasAction,
     
    [Parameter(Mandatory=$True,Position=1)]
    [ValidateLength(1,100)]
    [string]$ResourceGroupName,
 
    [Parameter(Mandatory=$True,Position=2)]
    [ValidateLength(1,100)]
    [string]$AnalysisServerName
)
 
# Keep track of time
$StartDate=(GET-DATE)
 
 
 
########################################################
# Log in to Azure with AZ (standard code)
########################################################
Write-Verbose -Message 'Connecting to Azure'
  
Import-module 'az.accounts'
Connect-AzAccount -Identity
########################################################
  
 
 
########################################################
# Getting the AAS for testing and logging purposes
########################################################
$myAzureAnalysisServer = Get-AzAnalysisServicesServer -ResourceGroupName $ResourceGroupName -Name $AnalysisServerName
if (!$myAzureAnalysisServer)
{
    Write-Error "$($AnalysisServerName) not found in $($ResourceGroupName)"
    return
}
else
{
    Write-Output "Current status of $($AnalysisServerName): $($myAzureAnalysisServer.State)"
}
 
 
 
########################################################
# Pause or Resume AAS
########################################################
# Check for incompatible actions
if (($AasAction -eq "start" -And $myAzureAnalysisServer.State -eq "Succeeded") -Or ($AasAction -eq "stop" -And $myAzureAnalysisServer.State -eq "Paused"))
{
    Write-Error "Cannot $($AasAction) $($AnalysisServerName) while the status is $($myAzureAnalysisServer.State)"
    return
}
# Resume Azure Analysis Services
    
$dayOfWeek = (get-date).DayOfWeek

 
if ($AasAction -eq "start")
{
    Write-Output "Now starting $($AnalysisServerName)"
    $null = Resume-AzAnalysisServicesServer -ResourceGroupName $ResourceGroupName -Name $AnalysisServerName
}
# Pause Azure Analysis Services
else
{
    Write-Output "Now stopping $($AnalysisServerName)"
    $null = Suspend-AzAnalysisServicesServer -ResourceGroupName $ResourceGroupName -Name $AnalysisServerName
}
 
 
 
########################################################
# Show when finished
########################################################
$Duration = NEW-TIMESPAN –Start $StartDate –End (GET-DATE)
Write-Output "Done in $([int]$Duration.TotalMinutes) minute(s) and $([int]$Duration.Seconds) second(s)"
