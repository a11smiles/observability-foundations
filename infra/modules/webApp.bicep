@description('Application unique name')
param applicationUniqueName string

@description('Primary region of the application')
param primaryRegion string

@description('Secondary region of the application')
param secondaryRegion string

@description('Domain: TLD domain name (contoso.com)')
param domainPrimaryDomain string

@description('Domain: id')
param domainId string

@description('Cosmos db instance id')
param cosmosdbId string

@description('Cosmos db api version')
param cosmosdbApiVersion string

@description('Cosmos db endpoint')
param cosmosdbEndpoint string

@description('Log analytics workspace Id')
param logAnalyticsWorkspaceId string

var minimizedPrimaryRegion = toLower(replace(primaryRegion, ' ', ''))
var minimizedSecondaryRegion = toLower(replace(secondaryRegion, ' ', ''))
var cosmosdbKey = listKeys(cosmosdbId, cosmosdbApiVersion).primaryMasterKey

resource primaryAppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${applicationUniqueName}-${minimizedPrimaryRegion}'
  location: primaryRegion
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaAIExtension'
    RetentionInDays: 90
    WorkspaceResourceId: logAnalyticsWorkspaceId
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource primaryAppServer 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${applicationUniqueName}-${minimizedPrimaryRegion}'
  location: primaryRegion
  sku: {
    name: 'P1v2'
    tier: 'PremiumV2'
    size: 'P1v2'
    family: 'Pv2'
    capacity: 3
  }
  kind: 'app'
  properties: {}
}

resource primaryAppServerAutoscale 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: '${primaryAppServer.name}-autoscale'
  location: primaryRegion
  properties: {
    profiles: [
      {
        name: 'Auto created default scale condition'
        capacity: {
          default: '3'
          maximum: '10'
          minimum: '3'
        }
        rules: [
          {
            scaleAction: {
              cooldown: 'PT5M'
              direction: 'Increase'
              type: 'ChangeCount'
              value: '2'
            }
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: primaryAppServer.id
              operator: 'GreaterThanOrEqual'
              statistic: 'Average'
              threshold: 60
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              dividePerInstance: false
            }
          }
          {
            scaleAction: {
              cooldown: 'PT5M'
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
            }
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: primaryAppServer.id
              operator: 'LessThanOrEqual'
              statistic: 'Average'
              threshold: 40
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              dividePerInstance: false
            }
          }
        ]
      }
    ]
    notifications: []
    targetResourceLocation: primaryRegion
    targetResourceUri: primaryAppServer.id
  }
}

resource primaryAppSite 'Microsoft.Web/sites@2022-03-01' = {
  name: '${applicationUniqueName}-${minimizedPrimaryRegion}'
  location: primaryRegion
  kind: 'app'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${applicationUniqueName}-${minimizedPrimaryRegion}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${applicationUniqueName}-${minimizedPrimaryRegion}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: primaryAppServer.id
    reserved: false
    isXenon: false
    hyperV: false
    vnetRouteAllEnabled: false
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    siteConfig: {
      numberOfWorkers: 1
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 0
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: primaryAppInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: primaryAppInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'Recommended'
        }
        {
          name: 'CosmosDb__Account'
          value: cosmosdbEndpoint
        }
        {
          name: 'CosmosDb__Key'
          value: cosmosdbKey
        }
      ]
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: true
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    containerSize: 0
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

module primaryDomainVerify 'domainVerify.bicep' = {
  name: 'primaryDomainVerify'
  params: {
    domainPrimaryDomain: domainPrimaryDomain
    verificationnId: primaryAppSite.properties.customDomainVerificationId
  }
}

resource primaryAppSiteDomain 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  name: '${primaryAppSite.name}/tm.${domainPrimaryDomain}'
  properties: {
    azureResourceName: primaryAppSite.name
    azureResourceType: 'Website'
    domainId: domainId
    hostNameType: 'Managed'
    sslState: 'Disabled'
    siteName: primaryAppSite.name
  }
}

resource primaryAppServerHostCert 'Microsoft.Web/certificates@2022-03-01' = {
  name: 'tm.${domainPrimaryDomain}-${minimizedPrimaryRegion}'
  location: primaryRegion
  properties: {
    serverFarmId: primaryAppServer.id
    canonicalName: 'tm.${domainPrimaryDomain}'
  }
}

module primaryCustomHostEnable 'sni-enable.bicep' = {
  name: 'primaryCustomHostEnable'
  dependsOn: [
    primaryDomainVerify
  ]
  params: {
    appServerHostCertName: 'tm.${domainPrimaryDomain}'
    appServerHostCertThumbprint: primaryAppServerHostCert.properties.thumbprint
    appSiteName: primaryAppSite.name
  }
}

resource primaryAppServerDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'LogAnalytics'
  scope: primaryAppServer
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: []
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource primaryAppSiteDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'LogAnalytics'
  scope: primaryAppSite
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AppServiceAntivirusScanAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceFileAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource secondaryAppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${applicationUniqueName}-${minimizedSecondaryRegion}'
  location: secondaryRegion
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaAIExtension'
    RetentionInDays: 90
    WorkspaceResourceId: logAnalyticsWorkspaceId
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource secondaryAppServer 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${applicationUniqueName}-${minimizedSecondaryRegion}'
  dependsOn: [
    primaryCustomHostEnable
  ]
  location: secondaryRegion
  sku: {
    name: 'S1'
    tier: 'Standard'
    size: 'S1'
    family: 'S'
    capacity: 1
  }
  kind: 'app'
  properties: {}
}

resource secondaryAppServerAutoscale 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: '${secondaryAppServer.name}-autoscale'
  location: secondaryRegion
  properties: {
    profiles: [
      {
        name: 'Auto created default scale condition'
        capacity: {
          default: '1'
          maximum: '10'
          minimum: '1'
        }
        rules: [
          {
            scaleAction: {
              cooldown: 'PT5M'
              direction: 'Increase'
              type: 'ChangeCount'
              value: '2'
            }
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: secondaryAppServer.id
              operator: 'GreaterThanOrEqual'
              statistic: 'Average'
              threshold: 60
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              dividePerInstance: false
            }
          }
          {
            scaleAction: {
              cooldown: 'PT5M'
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
            }
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: secondaryAppServer.id
              operator: 'LessThanOrEqual'
              statistic: 'Average'
              threshold: 40
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              dividePerInstance: false
            }
          }
        ]
      }
    ]
    notifications: []
    targetResourceLocation: secondaryRegion
    targetResourceUri: secondaryAppServer.id
  }
}

resource secondaryAppSite 'Microsoft.Web/sites@2022-03-01' = {
  name: '${applicationUniqueName}-${minimizedSecondaryRegion}'
  location: secondaryRegion
  kind: 'app'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${applicationUniqueName}-${minimizedSecondaryRegion}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${applicationUniqueName}-${minimizedSecondaryRegion}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: secondaryAppServer.id
    reserved: false
    isXenon: false
    hyperV: false
    vnetRouteAllEnabled: false
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    siteConfig: {
      numberOfWorkers: 1
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 0
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: secondaryAppInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: secondaryAppInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'Recommended'
        }
        {
          name: 'CosmosDb__Account'
          value: cosmosdbEndpoint
        }
        {
          name: 'CosmosDb__Key'
          value: cosmosdbKey
        }
      ]
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: true
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    containerSize: 0
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

module secondaryDomainVerify 'domainVerify.bicep' = {
  name: 'secondaryDomainVerify'
  dependsOn: [
    primaryCustomHostEnable
  ]
  params: {
    domainPrimaryDomain: domainPrimaryDomain
    verificationnId: secondaryAppSite.properties.customDomainVerificationId
  }
}

resource secondaryAppSiteDomain 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  name: '${secondaryAppSite.name}/tm.${domainPrimaryDomain}'
  properties: {
    azureResourceName: secondaryAppSite.name
    azureResourceType: 'Website'
    domainId: domainId
    hostNameType: 'Managed'
    sslState: 'Disabled'
    siteName: secondaryAppSite.name
  }
}

resource secondaryAppServerHostCert 'Microsoft.Web/certificates@2022-03-01' = {
  name: 'tm.${domainPrimaryDomain}-${minimizedSecondaryRegion}'
  location: secondaryRegion
  properties: {
    serverFarmId: secondaryAppServer.id
    canonicalName: 'tm.${domainPrimaryDomain}'
  }
}

module secondaryCustomHostEnable 'sni-enable.bicep' = {
  name: 'secondaryCustomHostEnable'
  dependsOn: [
    secondaryDomainVerify
  ]
  params: {
    appServerHostCertName: 'tm.${domainPrimaryDomain}'
    appServerHostCertThumbprint: secondaryAppServerHostCert.properties.thumbprint
    appSiteName: secondaryAppSite.name
  }
}

resource secondaryAppServerDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'LogAnalytics'
  scope: secondaryAppServer
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: []
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource secondaryAppSiteDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'LogAnalytics'
  scope: secondaryAppSite
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}



@description('Name of primary web server')
output primaryAppServerName string = primaryAppServer.name

@description('Name of primary web server autoscale settings')
output primaryAppServerAutoscaleName string = primaryAppServerAutoscale.name

@description('Name of primary web site')
output primaryAppSiteName string = primaryAppSite.name

@description('FQDN of primary web site')
output primaryAppSiteFqdn string = primaryAppSite.properties.defaultHostName

@description('Name of secondary web server')
output secondaryAppServerName string = secondaryAppServer.name

@description('Name of secondary web server autoscale settings')
output secondaryAppServerAutoscaleName string = secondaryAppServerAutoscale.name

@description('Name of secondary web site')
output secondaryAppSiteName string = secondaryAppSite.name

@description('FQDN of secondary web site')
output secondaryAppSiteFqdn string = secondaryAppSite.properties.defaultHostName
