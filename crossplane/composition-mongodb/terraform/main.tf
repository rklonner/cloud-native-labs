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
