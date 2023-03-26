$envSuffix = "-prod"
$location = "westeurope"

#Base deployment
New-AzSubscriptionDeployment -Name BaseDeployment -location $location -TemplateFile /Users/emilw/Library/CloudStorage/OneDrive-Personal/Prezentacje/2022/CloudBrew/Bicep/Demo4/core/base_deployment.bicep -envSuffix $envSuffix


#Main Deployment
New-AzSubscriptionDeployment -Name MainDeployment -location $location -TemplateFile /Users/emilw/Library/CloudStorage/OneDrive-Personal/Prezentacje/2022/CloudBrew/Bicep/Demo4/core/deployment.bicep -envSuffix $envSuffix
