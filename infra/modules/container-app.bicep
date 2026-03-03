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

// Grubify Container App
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
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
          image: 'ghcr.io/dm-chelupati/grubify:latest'
          name: 'grubify'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'PORT'
              value: '8080'
            }
            {
              name: 'NODE_ENV'
              value: 'production'
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
