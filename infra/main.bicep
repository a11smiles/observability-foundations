@description('Primary region of the application')
param primaryRegion string

@description('Secondary region of the application')
param secondaryRegion string

@description('Failover region for cosmos db')
param cosmosdbFailoverRegion string

@description('Domain: TLD domain name (contoso.com)')
param domainPrimaryDomain string

@description('Domain: Email address')
param domainPrimaryEmail string

@description('Domain: First name ')
param domainPrimaryFirstName string

@description('Domain: Last name ')
param domainPrimaryLastName string

@description('Domain: Phone ')
param domainPrimaryPhone string

@description('Domain: Mailing Address 1')
param domainPrimaryAddress1 string

@description('Domain: Mailing Address 2')
param domainPrimaryAddress2 string

@description('Domain: Mailing City')
param domainPrimaryCity string

@description('Domain: Mailing Country')
param domainPrimaryCountry string

@description('Domain: Mailing Postal Code')
param domainPrimaryPostalCode string

@description('Domain: Mailing State')
param domainPrimaryState string

@description('My IP address')
param myIPAddress string



param guidValue string = resourceGroup().id
var applicationShortName = replace(substring(domainPrimaryDomain, 0, indexOf(domainPrimaryDomain, '.')), '-', '')
var applicationUniqueName = '${applicationShortName}${uniqueString(guidValue)}'



module dns 'modules/dns.bicep' = {
  name: 'dns'
  params: {
    domainPrimaryDomain: domainPrimaryDomain
    domainPrimaryEmail: domainPrimaryEmail
    domainPrimaryFirstName: domainPrimaryFirstName
    domainPrimaryLastName: domainPrimaryLastName
    domainPrimaryPhone: domainPrimaryPhone
    domainPrimaryAddress1: domainPrimaryAddress1
    domainPrimaryAddress2: domainPrimaryAddress2
    domainPrimaryCity: domainPrimaryCity
    domainPrimaryCountry: domainPrimaryCountry
    domainPrimaryPostalCode: domainPrimaryPostalCode
    domainPrimaryState: domainPrimaryState
    myIPAddress: myIPAddress
  }
}

module logAnalytics 'modules/logAalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    primaryRegion: primaryRegion
    workspaceName: applicationUniqueName
  }
}

module cosmosdb 'modules/cosmos.bicep' = {
  name: 'cosmosdb'
  params: {
    applicationUniqueName: applicationUniqueName
    cosmosdbFailoverRegion: cosmosdbFailoverRegion
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    primaryRegion: primaryRegion
  }
}

module webApp 'modules/webApp.bicep' = {
  name: 'webapp'
  params: {
    applicationUniqueName: applicationUniqueName
    domainPrimaryDomain: domainPrimaryDomain
    domainId: dns.outputs.domainId
    logAnalyticsWorkspaceId:  logAnalytics.outputs.logAnalyticsWorkspaceId
    primaryRegion: primaryRegion
    secondaryRegion: secondaryRegion
    cosmosdbApiVersion: cosmosdb.outputs.cosmosdbApiVersion
    cosmosdbEndpoint: cosmosdb.outputs.cosmosdbEndpoint
    cosmosdbId: cosmosdb.outputs.cosmosdbId
  }
}

module trafficManager 'modules/trafficManager.bicep' = {
  name: 'trafficManager'
  params: {
    applicationUniqueName: applicationUniqueName
    domainPrimaryDomain: domainPrimaryDomain
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    primaryRegionFqdn: webApp.outputs.primaryAppSiteFqdn
    secondaryRegionFqdn: webApp.outputs.secondaryAppSiteFqdn
  }
}

output subscriptionId string = subscription().subscriptionId
output resourceGroupName string = resourceGroup().name
output applicationUniqueName string = applicationUniqueName
output logAnalyticsWorkspaceId string = logAnalytics.outputs.logAnalyticsWorkspaceId
output logAnalyticsWorkspaceName string = logAnalytics.outputs.logAnalyticsWorkspaceName
output cosmosdbName string = cosmosdb.outputs.cosmosdbName
output cosmosdbEndpoint string = cosmosdb.outputs.cosmosdbEndpoint
output primaryAppServerName string = webApp.outputs.primaryAppServerName
output primaryAppServerAutoscaleName string = webApp.outputs.primaryAppServerAutoscaleName
output primaryAppSiteName string = webApp.outputs.primaryAppSiteName
output secondaryAppServerName string = webApp.outputs.secondaryAppServerName
output secondaryAppServerAutoscaleName string = webApp.outputs.secondaryAppServerAutoscaleName
output secondaryAppSiteName string = webApp.outputs.secondaryAppSiteName
output trafficManagerName string = trafficManager.outputs.trafficManagerName
output trafficManagerUri string = trafficManager.outputs.trafficManagerUri
