@description('Location for resources')
param location string

@description('Container App Environment name')
param containerAppEnvName string

@description('Container App name')
param containerAppName string

@description('Log Analytics Workspace resource ID')
param logAnalyticsWorkspaceId string

@description('Log Analytics Workspace shared key')
@secure()
param logAnalyticsWorkspaceKey string

// Container App Environment
resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerAppEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspaceId, '2023-09-01').customerId
        sharedKey: logAnalyticsWorkspaceKey
      }
    }
  }
}

// Azure Container Registry (for azd to push built images)
var acrName = replace('acr${containerAppName}', '-', '')
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: length(acrName) > 50 ? substring(acrName, 0, 50) : acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// Grubify Container App (placeholder — azd deploy will update the image)
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      registries: [
        {
          server: acr.properties.loginServer
          username: acr.listCredentials().username
          passwordSecretRef: 'acr-password'
        }
      ]
      secrets: [
        {
          name: 'acr-password'
          value: acr.listCredentials().passwords[0].value
        }
      ]
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
        allowInsecure: false
      }
    }
    template: {
      containers: [
        {
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          name: 'grubify-api'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://+:8080'
            }
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Production'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

// Outputs
output containerAppId string = containerApp.id
output containerAppName string = containerApp.name
output containerAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output containerAppEnvId string = containerAppEnv.id
output containerAppEnvName string = containerAppEnv.name
output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
