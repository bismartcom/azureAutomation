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
  
# Name of the Azure Run As connection
$ConnectionName = 'AzureRunAsConnection'
try
{
    # Get the connection properties
    $ServicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName      
   
    'Log in to Azure...'
    $null = Connect-AzAccount `
        -ServicePrincipal `
        -TenantId $ServicePrincipalConnection.TenantId `
        -ApplicationId $ServicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint 
}
catch 
{
    if (!$ServicePrincipalConnection)
    {
        # You forgot to turn on 'Create Azure Run As account' 
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    }
    else
    {
        # Something else went wrong
        Write-Error -Message $_.Exception.Message
        throw $_.Exception
    }
}
########################################################
  
########################################################
# Getting the DWH connection
########################################################

$database = Get-AzSqlDatabase –ResourceGroupName $rg –ServerName $ServerName –DatabaseName $DwhName
Write-Output "Actual Status $($database.Status)"
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


 
 
########################################################
# Show when finished
########################################################
$Duration = NEW-TIMESPAN –Start $StartDate –End (GET-DATE)
Write-Output "Done in $([int]$Duration.TotalMinutes) minute(s) and $([int]$Duration.Seconds) second(s)"
