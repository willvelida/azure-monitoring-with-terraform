terraform {
    required_version = ">=0.12"
    required_providers {
      azurerm = {
        source = "hashicorp/azurerm"
        version = "~>3.0"
      }
    }
}

provider "azurerm" {
    features {}
}

resource "azurerm_resource_group" "rg" {
    name = var.resource_group_name
    location = var.location
}


## Azure Log Analytics
resource "azurerm_log_analytics_workspace" "law" {
  name = var.log_analytics_workspace
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku = "PerGB2018"
  retention_in_days = 30
}

## Application Insights
resource "azurerm_application_insights" "ai" {
  name = var.app_insights_name
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id = azurerm_log_analytics_workspace.law.id
  application_type = "web"
}

## App Service Plan
resource "azurerm_service_plan" "asp" {
  name = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  os_type = "Linux"
  sku_name = "EP1"
  maximum_elastic_worker_count = 20
  worker_count = 3
  zone_balancing_enabled = true
}

## Azure Storage
resource "azurerm_storage_account" "funcstor" {
  name = var.storage_account_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_tier = "Standard"
  account_replication_type = "LRS"
  access_tier = "Hot"
  enable_https_traffic_only = true
}

## Azure Service Bus
resource "azurerm_servicebus_namespace" "sbnamespace" {
  name = var.service_bus_namespace_name
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku = "Premium"
  capacity = 1
  zone_redundant = true
}

resource "azurerm_servicebus_queue" "sbqueue" {
  name = var.queue_name
  namespace_id = azurerm_servicebus_namespace.sbnamespace.id
  enable_express = false
}

## Azure Cosmos DB
resource "azurerm_cosmosdb_account" "cosmosdb" {
  name = var.cosmos_account_name
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type = "Standard"
  kind = "GlobalDocumentDB"
  consistency_policy {
   consistency_level = "Session" 
  }
  geo_location {
   location = azurerm_resource_group.rg.location
   failover_priority = 0
   zone_redundant = true
  }
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name = var.database_name
  resource_group_name = azurerm_cosmosdb_account.cosmosdb.resource_group_name
  account_name = azurerm_cosmosdb_account.cosmosdb.name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  name = var.container_name
  resource_group_name = azurerm_cosmosdb_account.cosmosdb.resource_group_name
  account_name = azurerm_cosmosdb_account.cosmosdb.name
  database_name = azurerm_cosmosdb_sql_database.db.name
  partition_key_path = "/transactionId"
  autoscale_settings {
    max_throughput = 4000
  }
}

## Function App
resource "azurerm_linux_function_app" "funcapp" {
    name = var.function_app_name
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    service_plan_id = azurerm_service_plan.asp.id
    storage_account_name = azurerm_storage_account.funcstor.name
    storage_account_access_key = azurerm_storage_account.funcstor.primary_access_key
    app_settings = {
      "APPINSIGHTS_INSTRUMENTATIONKEY" = "${azurerm_application_insights.ai.instrumentation_key}"
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = "InstrumentationKey=${azurerm_application_insights.ai.instrumentation_key};IngestionEndpoint=https://australiaeast-1.in.applicationinsights.azure.com/;LiveEndpoint=https://australiaeast.livediagnostics.monitor.azure.com/"
    }
    site_config {
      
    }
}

## Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "aspdiag" {
    name = var.asp_diagnostics
    target_resource_id = azurerm_service_plan.asp.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

    metric {
     category = "AllMetrics"
     enabled = true 
    }
}

resource "azurerm_monitor_diagnostic_setting" "cosmosdiag" {
  name = var.cosmos_diagnostics
  target_resource_id = azurerm_cosmosdb_account.cosmosdb.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  metric {
    category = "Requests"
    enabled = true
  }

  log {
    category = "DataPlaneRequests"
    enabled = true
  }

  log {
    category = "QueryRuntimeStatistics"
    enabled = true
  }

  log {
    category = "PartitionKeyStatistics"
    enabled = true
  }

  log {
    category = "PartitionKeyRUConsumption"
    enabled = true
  }

  log {
    category = "ControlPlaneRequests"
    enabled = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "sbdiag" {
  name = var.service_bus_diagnostics
  target_resource_id = azurerm_service_plan.asp.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  metric {
     category = "AllMetrics"
     enabled = true 
  }
}

resource "azurerm_monitor_diagnostic_setting" "funcdiag" {
  name = var.function_diagnostics
  target_resource_id = azurerm_linux_function_app.funcapp.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  metric {
     category = "AllMetrics"
     enabled = true 
  }

  log {
   category = "FunctionAppLogs"
   enabled = true 
  }
}