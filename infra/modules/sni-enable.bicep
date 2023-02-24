@description('App site name')
param appSiteName string

@description('App server certificate name')
param appServerHostCertName string

@description('App server certificate thumbprint')
param appServerHostCertThumbprint string



resource appSiteDomainEnable 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  name: '${appSiteName}/${appServerHostCertName}'
  properties: {
    sslState: 'SniEnabled'
    thumbprint: appServerHostCertThumbprint
  }
}
