@description('Location for resources')
param location string

@description('Container App name')
param containerAppName string

@description('Container App resource ID')
param containerAppId string

@description('Log Analytics Workspace resource ID')
param logAnalyticsWorkspaceId string

@description('Environment name for naming')
param environmentName string

// ============================================================
// Action Group (minimal - SRE Agent picks up alerts via managed resources)
// ============================================================
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-sre-lab-${environmentName}'
  location: 'global'
  properties: {
    groupShortName: 'SRELabAG'
    enabled: true
  }
}

// ============================================================
// Metric Alert: HTTP 5xx errors on Container App
// ============================================================
resource http5xxAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-http-5xx-${environmentName}'
  location: 'global'
  properties: {
    description: 'Alert when Grubify returns HTTP 5xx errors'
    severity: 3
    enabled: true
    scopes: [
      containerAppId
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'http5xx'
          metricName: 'Requests'
          metricNamespace: 'microsoft.app/containerapps'
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Total'
          dimensions: [
            {
              name: 'statusCodeCategory'
              operator: 'Include'
              values: [
                '5xx'
              ]
            }
          ]
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// ============================================================
// Log Alert: Error-level log entries
// ============================================================
resource logErrorAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'alert-log-errors-${environmentName}'
  location: location
  properties: {
    description: 'Alert when error-level logs spike in Grubify'
    severity: 3
    enabled: true
    scopes: [
      logAnalyticsWorkspaceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: '''
            ContainerAppConsoleLogs_CL
            | where ContainerAppName_s == "${containerAppName}"
            | where Log_s contains "error" or Log_s contains "Error" or Log_s contains "500"
            | summarize ErrorCount = count()
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 10
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
  }
}
