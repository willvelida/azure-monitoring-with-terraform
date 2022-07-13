variable "resource_group_name" {
  default = "azmonitorsample-rg"
  type = string
}

variable "location" {
  default = "australiaeast"
  type = string
}

variable "log_analytics_workspace" {
 default = "wvsamplelaw" 
}

variable "app_insights_name" {
  default = "wvappins"
}

variable "app_service_plan_name" {
  default = "wvasp"
}

variable "storage_account_name" {
  default = "wvfuncstor"
}

variable "service_bus_namespace_name" {
  default = "wvservicebus"
}

variable "queue_name" {
  default = "transactions"
}

variable "cosmos_account_name" {
  default = "wvcosmosdb"
}

variable "database_name" {
  default = "transactionsdb"
}

variable "container_name" {
  default = "transactions"
}

variable "function_app_name" {
  default = "wvtransactionsapp"
}

variable "asp_diagnostics" {
  default = "aspdiagnostics"
}

variable "cosmos_diagnostics" {
  default = "cosmosdiagnostics"
}

variable "service_bus_diagnostics" {
  default = "servicebusdiagnostics"
}

variable "function_diagnostics" {
  default = "funcdiagnostics"
}