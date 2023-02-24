@description('Domain: TLD domain name (contoso.com)')
param domainPrimaryDomain string

@description('Verificaton Id')
param verificationnId string

resource domainVerify 'Microsoft.Network/dnsZones/TXT@2018-05-01' = {
  name: '${domainPrimaryDomain}/asuid.tm'
  properties: {
    TTL: 3600
    TXTRecords: [
      {
        value: [
          verificationnId
        ]
      }
    ]
  }
}
