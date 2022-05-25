<#
.SYNOPSIS
    Vertically scale an Azure SQL Database up or down according to a
    schedule using Azure Automation, using powershell 7.*

.DESCRIPTION
    This Azure Automation runbook enables vertically scaling of
    an Azure SQL Database according to a schedule. Autoscaling based
    on a schedule allows you to scale your solution according to
    predictable resource demand. For example you could require a
    high capacity (e.g. P2) on Monday during peak hours, while the rest
    of the week the traffic is decreased allowing you to scale down
    (e.g. P1). Outside business hours and during weekends you could then
    scale down further to a minimum (e.g. S0). This runbook
    can be scheduled to run hourly. The code checks the
    scalingSchedule parameter to decide if scaling needs to be
    executed, or if the database is in the desired state already and
    no work needs to be done. The script is Timezone aware.

.PARAMETER resourceGroupName
    Name of the resource group to which the database server is
    assigned.

.PARAMETER serverName
    Azure SQL Database server name.

.PARAMETER databaseName
    Azure SQL Database name (case sensitive).


.PARAMETER defaultEdition
    Azure SQL Database Edition that will be used outside the slots
    specified in the scalingSchedule paramater value.
    Available values: Basic, Standard, Premium.

.PARAMETER tier
    Azure SQL Database Tier that will be used outside the slots
    specified in the scalingSchedule paramater value.
    Example values: Basic, S0, S1, S2, S3, P1, P2, P4, P6, P11, P15.


.NOTES
    Author: joan teixi
    Last Update: May, 2022  
#>

param(

[parameter(Mandatory=$true)]
[string] $resourceGroupName,

[parameter(Mandatory=$true)]
[string] $serverName,

[parameter(Mandatory=$true)]
[string] $databaseName,

[parameter(Mandatory=$false)]
[string] $defaultEdition = "Basic",

[parameter(Mandatory=$false)]
[string] $tier = "S0"
)

filter timestamp {"[$(Get-Date -Format G)]: $_"}

Write-Output "Script started." | timestamp


# Authentication
## Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

## Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context

## set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

# Autoscale...
Set-AzSqlDatabase  `
	-ResourceGroupName $resourceGroupName `
	-DatabaseName $databaseName `
	-ServerName $serverName `
	-Edition $defaultEdition `
	-RequestedServiceObjectiveName $tier


Write-Output "Script finished." | timestamp