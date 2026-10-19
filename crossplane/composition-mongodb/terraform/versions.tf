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
