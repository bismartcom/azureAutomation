######################
# Dependencies:
#   Az.Accounts
#   Az.Compute
#   Az.Resources
#
#######################

param (

    [Parameter(Mandatory = $true)]  
    [String] $Action,

    [Parameter(Mandatory = $true)]
    [String] $Rg,

    [Parameter(Mandatory = $false)]  
    [String] $TagName,

    [Parameter(Mandatory = $false)]
    [String] $TagValue
) 

## Authentication
Write-Output ""
Write-Output "------------------------ Authentication ------------------------"
Write-Output "Logging into Azure ..."


########################################################
# Log in to Azure with AZ (standard code)
########################################################
Write-Verbose -Message 'Connecting to Azure'
  
# Name of the Azure Run As connection
$ConnectionName = 'AzureRunAsConnection'
try {
    # Get the connection properties
    $ServicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName      
   
    'Log in to Azure...'
    $null = Connect-AzAccount `
        -ServicePrincipal `
        -TenantId $ServicePrincipalConnection.TenantId `
        -ApplicationId $ServicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$ServicePrincipalConnection) {
        # You forgot to turn on 'Create Azure Run As account' 
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    }
    else {
        # Something else went wrong
        Write-Error -Message $_.Exception.Message
        throw $_.Exception
    }
}
########################################################
  
 

## Getting all virtual machines with tag 'start-stop'
Write-Output ""
Write-Output ""
Write-Output "---------------------------- Status ----------------------------"
Write-Output "Getting all virtual machines from resource group ..."

try {
    if ($TagName) {                    
        $instances = Get-AzResource -TagName $TagName -TagValue $TagValue -ResourceGroupName $Rg -ResourceType "Microsoft.Compute/virtualMachines"
        
        if ($instances) {
            $resourceGroupsContent = @()
                                      
            foreach ($instance in $instances) {
                $instancePowerState = (((Get-AzVM -ResourceGroupName $($instance.ResourceGroupName) -Name $($instance.Name) -Status).Statuses.Code[1]) -replace "PowerState/", "")

                $resourceGroupContent = New-Object -Type PSObject -Property @{
                    "Resource group name" = $($instance.ResourceGroupName)
                    "Instance name"       = $($instance.Name)
                    "Instance type"       = (($instance.ResourceType -split "/")[0].Substring(10))
                    "Instance state"      = ([System.Threading.Thread]::CurrentThread.CurrentCulture.TextInfo.ToTitleCase($instancePowerState))
                    $TagName              = $TagValue
                }

                $resourceGroupsContent += $resourceGroupContent
            }
        }
        else {
            #Do nothing
        }
    }       
    else {
        $instances = Get-AzResource -ResourceType "Microsoft.Compute/virtualMachines" -ResourceGroupName $Rg

        if ($instances) {
            $resourceGroupsContent = @() 
                  
            foreach ($instance in $instances) {
                $instancePowerState = (((Get-AzVM -ResourceGroupName $($instance.ResourceGroupName) -Name $($instance.Name) -Status).Statuses.Code[1]) -replace "PowerState/", "")

                $resourceGroupContent = New-Object -Type PSObject -Property @{
                    "Resource group name" = $($instance.ResourceGroupName)
                    "Instance name"       = $($instance.Name)
                    "Instance type"       = (($instance.ResourceType -split "/")[0].Substring(10))
                    "Instance state"      = ([System.Threading.Thread]::CurrentThread.CurrentCulture.TextInfo.ToTitleCase($instancePowerState))
                }

                $resourceGroupsContent += $resourceGroupContent
            }
        }
        else {
            #Do nothing
        }
    }

    $resourceGroupsContent | Format-Table -AutoSize
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception    
}
## End of getting all virtual machines

$runningInstances = ($resourceGroupsContent | Where-Object { $_.("Instance state") -eq "Running" -or $_.("Instance state") -eq "Starting" })
$deallocatedInstances = ($resourceGroupsContent | Where-Object { $_.("Instance state") -eq "Deallocated" -or $_.("Instance state") -eq "Deallocating" })

## Updating virtual machines power state
if (($runningInstances) -and ($Action -eq "stop")) {
    Write-Output "--------------------------- Updating ---------------------------"
    Write-Output "Trying to stop virtual machines ..."

    try {
        $updateStatuses = @()
         
        foreach ($runningInstance in $runningInstances) {
            Write-Output "$($runningInstance.("Instance name")) is shutting down ..."
        
            $startTime = Get-Date -Format G

            $null = Stop-AzVM -ResourceGroupName $($runningInstance.("Resource group name")) -Name $($runningInstance.("Instance name")) -Force
            
            $endTime = Get-Date -Format G

            $updateStatus = New-Object -Type PSObject -Property @{
                "Resource group name" = $($runningInstance.("Resource group name"))
                "Instance name"       = $($runningInstance.("Instance name"))
                "Start time"          = $startTime
                "End time"            = $endTime
            }
            
            $updateStatuses += $updateStatus       
        }

        $updateStatuses | Format-Table -AutoSize
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.Exception    
    }
}
elseif (($deallocatedInstances) -and ($Action -eq "start")) {


    Write-Output "--------------------------- Updating ---------------------------"
    Write-Output "Trying to start virtual machines ..."

    try {
        $updateStatuses = @() 

        foreach ($deallocatedInstance in $deallocatedInstances) {                                    
            Write-Output "$($deallocatedInstance.("Instance name")) is starting ..."

            $startTime = Get-Date -Format G

            $null = Start-AzVM -ResourceGroupName $($deallocatedInstance.("Resource group name")) -Name $($deallocatedInstance.("Instance name"))

            $endTime = Get-Date -Format G

            $updateStatus = New-Object -Type PSObject -Property @{
                "Resource group name" = $($deallocatedInstance.("Resource group name"))
                "Instance name"       = $($deallocatedInstance.("Instance name"))
                "Start time"          = $startTime
                "End time"            = $endTime
            }

            $updateStatuses += $updateStatus
        }

        $updateStatuses | Format-Table -AutoSize
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.Exception    
    }
    
}
#### End of updating virtual machines power state