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

resource "azurerm_log_analytics_workspace" "law" {
  name = var.log_analytics_workspace
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku = "PerGB2018"
  retention_in_days = 30
}

resource "azurerm_application_insights" "ai" {
  name = var.app_insights_name
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id = azurerm_log_analytics_workspace.law.id
  application_type = "web"
}

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

resource "azurerm_storage_account" "funcstor" {
  name = var.storage_account_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_tier = "Standard"
  account_replication_type = "LRS"
  access_tier = "Hot"
  enable_https_traffic_only = true
}

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