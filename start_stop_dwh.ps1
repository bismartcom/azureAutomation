# PowerShell code
 
########################################################
# Parameters
########################################################
[CmdletBinding()]
param (

    [Parameter(Mandatory=$true)]  
    [ValidateSet('start','pause')]
    [String] $Action,

    [Parameter(Mandatory=$true)]  
    [String] $ServerName,

    [Parameter(Mandatory=$true)]
    [String] $DwhName,

    [Parameter(Mandatory=$true)]
    [String] $rg

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
# Getting the DWH connection
########################################################

$database = Get-AzSqlDatabase –ResourceGroupName $rg –ServerName $ServerName –DatabaseName $DwhName
Write-Output "Before script Status $($database.Status)"
#Suspend-AzSqlDatabase -ResourceGroupName $rg -ServerName $ServerName -DatabaseName $DwhName
#Write-Output "end"
#pause dwh
    


if ( ($Action -eq 'start' ) ) 
{
    $null = Resume-AzSqlDatabase -ResourceGroupName $rg -ServerName $ServerName -DatabaseName $DwhName

}


if ( ($Action -eq 'pause' )) 
{
    $null = Suspend-AzSqlDatabase -ResourceGroupName $rg -ServerName $ServerName -DatabaseName $DwhName
}

Write-Output "After script Status $($database.Status)"


 
 
########################################################
# Show when finished
########################################################
$Duration = NEW-TIMESPAN –Start $StartDate –End (GET-DATE)
Write-Output "Done in $([int]$Duration.TotalMinutes) minute(s) and $([int]$Duration.Seconds) second(s)"
