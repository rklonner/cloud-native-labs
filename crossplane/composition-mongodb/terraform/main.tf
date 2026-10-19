terraform {
  required_providers {
    mongodb = {
      source  = "Kaginari/mongodb"
      version = "~> 1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

variable "database_name" {
  type = string
}

variable "rw_username" {
  type = string
}

variable "ro_username" {
  type = string
}

variable "create_ro_user" {
  type    = bool
  default = true
}

locals {
  db_name   = var.database_name
  rw_user   = var.rw_username
  ro_user   = var.ro_username
  create_ro = var.create_ro_user
}

resource "random_password" "rw" {
  length  = 24
  special = true
}

resource "random_password" "ro" {
  count   = local.create_ro ? 1 : 0
  length  = 24
  special = true
}

resource "mongodb_db_collection" "sentinel" {
  db   = local.db_name
  name = "_crossplane_sentinel"
  deletion_protection = false
}

resource "mongodb_db_user" "rw" {
  auth_database = "admin"
  name          = local.rw_user
  password      = random_password.rw.result
  role {
    role = "readWrite"
    db   = local.db_name
  }
}

resource "mongodb_db_user" "ro" {
  count         = local.create_ro ? 1 : 0
  auth_database = "admin"
  name          = local.ro_user
  password      = random_password.ro[0].result
  role {
    role = "read"
    db   = local.db_name
  }
}

output "database_name" {
  value = local.db_name
}

output "rw_username" {
  value = local.rw_user
}

output "rw_password" {
  value     = random_password.rw.result
  sensitive = true
}

output "rw_connection_string" {
  value     = "mongodb://${local.rw_user}:${random_password.rw.result}@mongodb-test:27017/${local.db_name}?authSource=admin"
  sensitive = true
}

output "ro_username" {
  value = local.create_ro ? local.ro_user : ""
}

output "ro_password" {
  value     = local.create_ro ? random_password.ro[0].result : ""
  sensitive = true
}

output "ro_connection_string" {
  value     = local.create_ro ? "mongodb://${local.ro_user}:${random_password.ro[0].result}@mongodb-test:27017/${local.db_name}?authSource=admin" : ""
  sensitive = true
}
