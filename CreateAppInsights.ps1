param(
  [string] $applicationUnderTestTag, `
  [string] $environment, `
  [string] $resourceGroupName, `
  [string] $subscription, `
  [string] $appInsightsOwner, `
  [string] $location, `
  [switch] $localAzureLogin
  )

###################################################
# Create the Resource and Output the name and iKey
###################################################

# Select the azure subscription, if local development
if($localAzureLogin)
{
#If running locally, fiddler has to be launched to get around MS sign in traffic being blocked.
  Connect-AzureRmAccount
  Get-AzureRmSubscription –SubscriptionName $subscription | Select-AzureRmSubscription
}

#Check for existence of resource group
$existingResourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName
if($existingResourceGroup.ResourceGroupName -ne $resourceGroupName)
{
  Write-Host "resource group " $resourceGroupName " does not exist"
  return
}

# Check for existence of  resource
$appInsightsName = "$applicationUnderTestTag-$environment"
$resource = Get-AzureRmResource -Name $appInsightsName -ResourceType "Microsoft.Insights/components" -ResourceGroupName $resourceGroupName
if($resource.Name -eq $appInsightsName)
{
  Write-Host "resource " $resource.Name " already exists"
  return
}

# Create the App Insights Resource
$resource = New-AzureRmResource `
  -ResourceName $appInsightsName `
  -ResourceGroupName $resourceGroupName `
  -Tag @{ applicationType = "web"; applicationName = $applicationTagName; owner = $appInsightsOwner} `
  -ResourceType "Microsoft.Insights/components" `
  -Location "East US" `
  -PropertyObject @{"Application_Type"="web"} `
  -Force

# Give owner access to a person
New-AzureRmRoleAssignment `
  -SignInName $appInsightsOwner `
  -RoleDefinitionName Owner `
  -Scope $resource.ResourceId 

# Give reader access to all of IT
New-AzureRmRoleAssignment `
  -ObjectId da5bada7-49eb-48ab-9d21-d375ea4b82e0 `
  -RoleDefinitionName Reader `
  -Scope $resource.ResourceId 


$appInsightsResource = Get-AzureRmApplicationInsights -ResourceGroupName $resourceGroupName -Name $appInsightsName

# Display iKey
Write-Host "App Insights Name = " $appInsightsResource.Name
Write-Host "IKey = " $appInsightsResource.InstrumentationKey