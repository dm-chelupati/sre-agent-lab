@description('Location for resources')
param location string

@description('Managed Identity name')
param identityName string

// User-Assigned Managed Identity for the SRE Agent
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: identityName
  location: location
  properties: {
    isolationScope: 'Regional'
  }
}

// Role definitions
var readerRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'           // Reader
var monitoringReaderRoleId = '43d0d8ad-25c7-4714-9337-8ba259a9fe05' // Monitoring Reader
var logAnalyticsReaderRoleId = '73c42c96-874c-492b-b04d-ab87d138a893' // Log Analytics Reader

// Assign Reader role on the resource group
resource readerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, userAssignedIdentity.id, readerRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', readerRoleId)
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Assign Monitoring Reader role on the resource group
resource monitoringReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, userAssignedIdentity.id, monitoringReaderRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringReaderRoleId)
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Assign Log Analytics Reader role on the resource group
resource logAnalyticsReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, userAssignedIdentity.id, logAnalyticsReaderRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', logAnalyticsReaderRoleId)
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output identityId string = userAssignedIdentity.id
output identityName string = userAssignedIdentity.name
output identityPrincipalId string = userAssignedIdentity.properties.principalId
