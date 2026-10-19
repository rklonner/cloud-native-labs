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
