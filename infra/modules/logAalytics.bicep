@description('Primary region of the application')
param primaryRegion string

@description('Name of the log analytics workspace')
param workspaceName string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: workspaceName
  location: primaryRegion
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: 5
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('Log analytics workspace id')
output logAnalyticsWorkspaceId string = logAnalytics.id

@description('Log analytics workspace name')
output logAnalyticsWorkspaceName string = logAnalytics.name
