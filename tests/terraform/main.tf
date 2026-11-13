# A small configuration for testing the actions with: applying it twice with
# different variables gives a diff with a known set of changes.
#
#   locally run terraform apply -var environment=one -var 'containers=["alpha"]'
#   locally run terraform apply -var environment=two -var 'containers=["beta"]'
#
# changes the storage account's tag, adds container "beta" and removes "alpha".

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.12.0"
    }
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variable "environment" {
  description = "Set as the storage account's `environment` tag."
  type        = string
}

variable "containers" {
  description = "The blob containers to create in the storage account."
  type        = set(string)
}

variable "prefix" {
  description = "Prefixes the resources' names, so that several runs can share one Locally."
  type        = string
  default     = "snapdiff"
}

# Set by `locally run`.
variable "location" {
  type = string
}

resource "azurerm_resource_group" "test" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_storage_account" "test" {
  name                     = "${var.prefix}sa"
  resource_group_name      = azurerm_resource_group.test.name
  location                 = azurerm_resource_group.test.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = var.environment
  }
}

resource "azurerm_storage_container" "test" {
  for_each           = var.containers
  name               = each.value
  storage_account_id = azurerm_storage_account.test.id
}
