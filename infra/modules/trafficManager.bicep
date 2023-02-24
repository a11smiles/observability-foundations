@description('Application unique name')
param applicationUniqueName string

@description('Domain: TLD domain name (contoso.com)')
param domainPrimaryDomain string

@description('Primary region FQDN')
param primaryRegionFqdn string

@description('Secondary region FQDN')
param secondaryRegionFqdn string

@description('Log analytics workspace Id')
param logAnalyticsWorkspaceId string

resource trafficManager 'Microsoft.Network/trafficmanagerprofiles@2022-04-01-preview' = {
  name: applicationUniqueName
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Weighted'
    dnsConfig: {
      relativeName: applicationUniqueName
      ttl: 60
    }
    monitorConfig: {
      profileMonitorStatus: 'Online'
      protocol: 'HTTPS'
      port: 443
      path: '/probe.html'
      intervalInSeconds: 30
      toleratedNumberOfFailures: 3
      timeoutInSeconds: 10
      customHeaders: []
      expectedStatusCodeRanges: []
    }
    endpoints: [
      {
        name: 'primary'
        type: 'Microsoft.Network/TrafficManagerProfiles/ExternalEndpoints'
        properties: {
          endpointStatus: 'Enabled'
          target: primaryRegionFqdn
          weight: 50
        }
      }
      {
        name: 'secondary'
        type: 'Microsoft.Network/TrafficManagerProfiles/ExternalEndpoints'
        properties: {
          endpointStatus: 'Enabled'
          target: secondaryRegionFqdn
          weight: 50
        }
      }

    ]
    trafficViewEnrollmentStatus: 'Disabled'
  }
}

resource domainCname 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  name: '${domainPrimaryDomain}/tm'
  properties: {
    TTL: 3600
    CNAMERecord: {
       cname: trafficManager.properties.dnsConfig.fqdn
    }
  }
}

resource trafficManagerDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'LogAnalytics'
  scope: trafficManager
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
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

@description('Name of the traffic manager')
output trafficManagerName string = trafficManager.name

@description('Public URI of the traffic manager')
output trafficManagerUri string = 'tm.${domainPrimaryDomain}'
