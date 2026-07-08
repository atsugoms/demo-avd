# Azure Monitor - Log Analytics Workspace and Data Collection Rules for AVD

# Log Analytics Workspace for AVD monitoring
resource "azurerm_log_analytics_workspace" "avd_log" {
  name                = "${var.prj}-${var.env}-avd-log"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Data Collection Rule for AVD session hosts (Performance Counters and Event Logs)
resource "azurerm_monitor_data_collection_rule" "avd_dcr" {
  name                = "${var.prj}-${var.env}-avd-dcr"
  resource_group_name = azurerm_resource_group.avd_rg.name
  location            = azurerm_resource_group.avd_rg.location
  kind                = "Windows"

  data_sources {
    performance_counter {
      name           = "AVDPerfCounterDataSource30"
      sampling_frequency_in_seconds = 30
      streams        = ["Microsoft-Perf"]

      counter_specifiers = [
        "\\LogicalDisk(C:)\\Avg. Disk Queue Length",
        "\\LogicalDisk(C:)\\Current Disk Queue Length",
        "\\Memory\\Available Mbytes",
        "\\Memory\\Page Faults/sec",
        "\\Memory\\Pages/sec",
        "\\Memory\\% Committed Bytes In Use",
        "\\PhysicalDisk(*)\\Avg. Disk Queue Length",
        "\\PhysicalDisk(*)\\Avg. Disk sec/Read",
        "\\PhysicalDisk(*)\\Avg. Disk sec/Transfer",
        "\\PhysicalDisk(*)\\Avg. Disk sec/Write",
        "\\Processor Information(_Total)\\% Processor Time",
        "\\User Input Delay per Process(*)\\Max Input Delay",
        "\\User Input Delay per Session(*)\\Max Input Delay"
      ]
    }

    performance_counter {
      name           = "AVDPerfCounterDataSource60"
      sampling_frequency_in_seconds = 60
      streams        = ["Microsoft-Perf"]

      counter_specifiers = [
        "\\LogicalDisk(C:)\\% Free Space",
        "\\LogicalDisk(C:)\\Avg. Disk sec/Transfer"
      ]
    }

    windows_event_log {
      name    = "AVDEventLogsDataSource"
      streams = ["Microsoft-Event"]

      x_path_queries = [
        "Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]",
        "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]",
        "System!*",
        "Microsoft-FSLogix-Apps/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]",
        "Application!*[System[(Level=2 or Level=3)]]",
        "Microsoft-FSLogix-Apps/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]"
      ]
    }
  }

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.avd_log.id
      name                  = "AVDLogAnalyticsDestination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf", "Microsoft-Event"]
    destinations = ["AVDLogAnalyticsDestination"]
  }
}

# AVD Insights solution for Workspace
resource "azurerm_log_analytics_solution" "avd_insights" {
  solution_name         = "VMInsights"
  location              = azurerm_log_analytics_workspace.avd_log.location
  resource_group_name   = azurerm_resource_group.avd_rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.avd_log.id
  workspace_name        = azurerm_log_analytics_workspace.avd_log.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }
}
