####### Azure Subscription, Locations and Resource Group ########
$subscriptionId = "xxxxxx"
$location01 = "EastAsia"
$location02 = "SoutheastAsia"
$resourceGroupName = "cdstudio"

######## Parameters Setting ##########
# --- Azure SQL ---
$dbServerName = "cdstudiodberver"								#Global Unique
$dbFirewallStartIp = "0.0.0.0"
$dbFirewallEndIp = "255.255.255.255"
$dbPerformanceLevel = "S2"

# --- Redis Cache ---
$redisName = "cdstudioRedisCache"								#Global Unique

# --- Web Application and Traffice Manager ---
$appServicePlanName01 = "cdstudioServicePlan01"
$appServicePlanName02 = "cdstudioServicePlan02"
$webAPI01AppName = "cdstudioAPI01"							#Global Unique
$webAPI02AppName = "cdstudioAPI02"							#Global Unique
$webAdminAppName = "cdstudioAdmin"								#Global Unique
$webSuperAdminAppName = "cdstudioSuperAdmin"						#Global Unique
$trafficManagerProfile = "cdstudioApiServiceProfile"				
$trafficManagerDNSName = "cdstudioapiservice"						#Global Unique

# --- Service Bus ---
$serviceBusNamespace = "cdstudioServiceBus"						#Global Unique

# --- Storage ---
$storageAccountName = "cdstudiostorage"							#Global Unique, low-char, and a-z only

# --- Document DB ---
$documentDBName = "cdstudiodocdb"								#Global Unique, low-char

# --- Service Fabric ---
$sfResourceGroup="cdstudioSF"
$sfClusterName="cdstudiocluster"
$vmUser="cdstudio"
$vmPwd="Password#1234"
$keyVaultName="cdstudioKeyVault"
$certPwd="12345"
$certSubName="CDS20.iotcenter.com"
$pfxfolder="D:\temp"
######## End of Parameters Setting #########

# --- Login to Azure, Specify Subscription ID ---
Add-AzureRmAccount
Select-AzureRMSubscription -SubscriptionId $subscriptionId

# --- Make Sure Azure Services Registered --- #
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.DocumentDB
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Sql
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Storage
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Web
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.KeyVault
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Compute
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Devices
Register-AzureRmResourceProvider -ProviderNamespace microsoft.insights
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Network
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.OperationalInsights
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Security
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Resources
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.ServiceBus
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.CertificateRegistration
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Cache
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.ServiceFabric

Set-ExecutionPolicy RemoteSigned -Force

######## Azure Service Deploy ##########

# --- Create ResourceGroup ---
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location01

# --- Create Azure SQL server and database ---
$dbCredential = Get-Credential
New-AzureRmSqlServer -ResourceGroupName $resourceGroupName `
    -ServerName $dbServerName `
    -Location $location02 `
    -SqlAdministratorCredentials $dbCredential

New-AzureRmSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
    -ServerName $dbServerName `
    -FirewallRuleName "AllowSome" -StartIpAddress $dbFirewallStartIp -EndIpAddress $dbFirewallEndIp

$databaseInst = New-AzureRmSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $dbServerName `
    -DatabaseName CDStudio `
    -RequestedServiceObjectiveName $dbPerformanceLevel
Set-Content configString.txt "DBConnection = data source=$($dbServerName).database.windows.net;initial catalog=CDStudio;persist security info=True;user id=$($dbCredential.GetNetworkCredential().UserName);password=$($dbCredential.GetNetworkCredential().password);MultipleActiveResultSets=True;App=EntityFramework`r`n"

# --- Create App Service Plan, Web Apps, Traffic Manager ---
New-AzureRmAppServicePlan -Name $appServicePlanName01 `
	-Location $location01 `
	-ResourceGroupName $resourceGroupName `
	-Tier Standard `
	-WorkerSize small `
	-NumberofWorkers 1

New-AzureRmAppServicePlan -Name $appServicePlanName02 `
	-Location $location02 `
	-ResourceGroupName $resourceGroupName `
	-Tier Standard `
	-WorkerSize small `
	-NumberofWorkers 1

$webAPI01Inst = New-AzureRmWebApp -Name $webAPI01AppName `
	-AppServicePlan $appServicePlanName01 `
	-ResourceGroupName $resourceGroupName `
	-Location $location01

$webAPI02Inst = New-AzureRmWebApp -Name $webAPI02AppName `
	-AppServicePlan $appServicePlanName02 `
	-ResourceGroupName $resourceGroupName `
	-Location $location02

New-AzureRmWebApp -Name $webAdminAppName `
	-AppServicePlan $appServicePlanName01 `
	-ResourceGroupName $resourceGroupName `
	-Location $location01
Add-Content configString.txt "sfAdminWebURI = http://$($webAdminAppName).azurewebsites.net/`r`n"
Add-Content configString.txt "sfAdminHeartbeatURL = http://$($webAdminAppName).azurewebsites.net/Monitor/RTMessageFeedIn`r`n"
Add-Content configString.txt "RTMessageFeedInURL = http://$($webAdminAppName).azurewebsites.net/Monitor/RTMessageFeedIn`r`n"

New-AzureRmWebApp -Name $webSuperAdminAppName `
	-AppServicePlan $appServicePlanName02 `
	-ResourceGroupName $resourceGroupName `
	-Location $location02
Add-Content configString.txt "sfSuperAdminHeartbeatURL = http://$($webSuperAdminAppName).azurewebsites.net/Monitor/RTMessageFeedIn`r`n"

New-AzureRmTrafficManagerProfile -Name $trafficManagerProfile `
	-ResourceGroupName $resourceGroupName `
	-ProfileStatus Enabled `
	-TrafficRoutingMethod Performance `
	-RelativeDnsName $trafficManagerDNSName `
	-TTL 300 `
	-MonitorProtocol HTTP `
	-MonitorPort 80 `
	-MonitorPath "/heartbeat"
Add-Content configString.txt "sfAPIServiceBaseURI = http://$($trafficManagerDNSName).trafficmanager.net/`r`n"

New-AzureRmTrafficManagerEndpoint -EndpointStatus Enabled `
	-Name $webAPI01AppName `
	-ProfileName $trafficManagerProfile `
	-ResourceGroupName $resourceGroupName `
	-Type AzureEndpoints `
	-TargetResourceId $webAPI01Inst.Id

New-AzureRmTrafficManagerEndpoint -EndpointStatus Enabled `
	-Name $webAPI02AppName `
	-ProfileName $trafficManagerProfile `
	-ResourceGroupName $resourceGroupName `
	-Type AzureEndpoints `
	-TargetResourceId $webAPI02Inst.Id

# --- Create App Service Bus, Queue and Topic ---
New-AzureRmServiceBusNamespace -ResourceGroup $resourceGroupName `
	-NamespaceName $serviceBusNamespace `
	-Location $location01 `
	-SkuName Standard

$serviceBusInst = Get-AzureRmServiceBusKey -ResourceGroup $resourceGroupName -NamespaceName $serviceBusNamespace -AuthorizationRuleName RootManageSharedAccessKey
Add-Content configString.txt "sfServiceBusConnectionString = $($serviceBusInst.PrimaryConnectionString)`r`n"

New-AzureRmServiceBusQueue -ResourceGroup $resourceGroupName `
	-NamespaceName $serviceBusNamespace `
	-QueueName infraops `
	-EnablePartitioning $True

New-AzureRmServiceBusQueue -ResourceGroup $resourceGroupName `
	-NamespaceName $serviceBusNamespace `
	-QueueName alarmops `
	-EnablePartitioning $True

New-AzureRmServiceBusTopic -ResourceGroup $resourceGroupName `
	-NamespaceName $serviceBusNamespace `
	-TopicName processcommand `
	-EnablePartitioning $True

# --- Create Azure Storage Account ---
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName `
	-AccountName $storageAccountName `
	-Location $location01 `
	-Type Standard_LRS

$storageKey = (Get-AzureRmStorageAccountKey -Name $storageAccountName -ResourceGroupName $resourceGroupName).Value[0]
Add-Content configString.txt "sfLogStorageName = $($storageAccountName)`r`n"
Add-Content configString.txt "sfLogStorageKey = $($storageKey)`r`n"
Add-Content configString.txt "StorageConnectionString = DefaultEndpointsProtocol=https;AccountName=$($storageAccountName);AccountKey=$($storageKey);EndpointSuffix=core.windows.net`r`n"

Set-AzureRmCurrentStorageAccount -ResourceGroupName $resourceGroupName `
	-AccountName $storageAccountName

"images log-admin-webapp log-apiservice log-audit-admin log-audit-superadmin log-backend-iothubeventprocessor log-backend-opsalarm log-backend-opsinfra log-device log-superadmin-webapp srvfabric".split() | New-AzureStorageContainer -Permission Off

# --- Create Azure Document DB ---
$iprangefilter = ""
$consistencyPolicy = @{"defaultConsistencyLevel"="Session"}
$DocumentDBProperties = @{"databaseAccountOfferType"="Standard"; "consistencyPolicy"=$consistencyPolicy; "ipRangeFilter"=$iprangefilter}
New-AzureRmResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
	-ApiVersion "2015-04-08" `
	-ResourceGroupName $resourceGroupName `
	-Location $location01 `
	-Name $documentDBName `
	-Force `
	-PropertyObject $DocumentDBProperties

$docDBKey = (Invoke-AzureRmResourceAction -Action listKeys -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName -Name $documentDBName -Force).primaryMasterKey
Add-Content configString.txt "sfDocDBConnectionString = AccountEndpoint=https://$($documentDBName).documents.azure.com:443/;AccountKey=$($docDBKey)`r`n"

# --- Create Redis Cache ---
$redisCacheInst = New-AzureRmRedisCache -ResourceGroupName $resourceGroupName `
	-Name $redisName `
	-Location $location01 `
	-Size C0 `
	-Sku Basic
Add-Content configString.txt "RedisCache = $($redisCacheInst.HostName):$($redisCacheInst.SslPort),password=$($redisCacheInst.PrimaryKey),ssl=True,abortConnect=False`r`n"


# --- Service Fabric ---
Add-Content configString.txt "sfSrvFabricCertificatePW = $certPwd`r`n"

$certPwd=$certPwd | ConvertTo-SecureString -AsPlainText -Force
$vmPwd=$vmPwd | ConvertTo-SecureString -AsPlainText -Force
$serviceFabricInst = New-AzureRmServiceFabricCluster `
	-ResourceGroupName $sfResourceGroup `
	-Name $sfClusterName `
	-Location $location01 `
	-KeyVaultResouceGroupName $resourceGroupName `
	-KeyVaultName $keyVaultName `
	-ClusterSize 3 `
	-VmUserName $vmUser `
	-VmPassword $vmPwd `
	-CertificateSubjectName $certSubName `
	-CertificateOutputFolder $pfxfolder `
	-CertificatePassword $certPwd `
	-OS WindowsServer2016Datacenter `
	-VmSku Standard_A1
Add-Content configString.txt "sfSrvFabricBaseURI = $($serviceFabricInst.Cluster.ManagementEndpoint)/`r`n"

