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
