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



resource dns 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: domainPrimaryDomain
  location: 'global'
  properties: {
    zoneType: 'Public'
  }
}
/*
resource dnsTmCname 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  name: 'tm'
  parent: dns
  properties: {
    TTL: 3600
    CNAMERecord: {
      cname: trafficManagerFQDN
    }
    targetResource: {}
  }
}
*/
resource domain 'Microsoft.DomainRegistration/domains@2022-03-01' = {
  name: domainPrimaryDomain
  location: 'global'
  properties: {
    privacy: true
    autoRenew: true
    dnsType: 'AzureDns'
    consent: {
      agreedBy: myIPAddress
      agreementKeys: ['DNRA','DNPA']
    }
    dnsZoneId: dns.id
    contactAdmin: {
      email: domainPrimaryEmail
      nameFirst: domainPrimaryFirstName
      nameLast: domainPrimaryLastName
      phone: domainPrimaryPhone
      addressMailing: {
        address1: domainPrimaryAddress1
        address2: domainPrimaryAddress2
        city: domainPrimaryCity
        country: domainPrimaryCountry
        postalCode: domainPrimaryPostalCode
        state: domainPrimaryState
      }
    }
    contactBilling: {
      email: domainPrimaryEmail
      nameFirst: domainPrimaryFirstName
      nameLast: domainPrimaryLastName
      phone: domainPrimaryPhone
      addressMailing: {
        address1: domainPrimaryAddress1
        address2: domainPrimaryAddress2
        city: domainPrimaryCity
        country: domainPrimaryCountry
        postalCode: domainPrimaryPostalCode
        state: domainPrimaryState
      }
    }
    contactRegistrant: {
      email: domainPrimaryEmail
      nameFirst: domainPrimaryFirstName
      nameLast: domainPrimaryLastName
      phone: domainPrimaryPhone
      addressMailing: {
        address1: domainPrimaryAddress1
        address2: domainPrimaryAddress2
        city: domainPrimaryCity
        country: domainPrimaryCountry
        postalCode: domainPrimaryPostalCode
        state: domainPrimaryState
      }
    }
    contactTech: {
      email: domainPrimaryEmail
      nameFirst: domainPrimaryFirstName
      nameLast: domainPrimaryLastName
      phone: domainPrimaryPhone
      addressMailing: {
        address1: domainPrimaryAddress1
        address2: domainPrimaryAddress2
        city: domainPrimaryCity
        country: domainPrimaryCountry
        postalCode: domainPrimaryPostalCode
        state: domainPrimaryState
      }
    }
  }
}

@description('Domain id')
output domainId string = domain.id
