# Similar to the conditional deployments example,
# if conditions can be used to filter a list of objects to create new objects.

variable "users" {
  type = map(object({
    is_admin = bool
  }))
  description = "A map of users."
  default = {
    "bob_user" = {
      is_admin = false
    }
    "tom_admin" = {
      is_admin = true
    }
  }
}

locals {
  admin_users = {
    for name, user in var.users : name => user
    if user.is_admin
  }
  regular_users = {
    for name, user in var.users : name => user
    if !user.is_admin
  }
}

output "filtering_admin_users" {
  description = "A map of admin users."
  value       = { for k, v in local.admin_users : k => v }
}

output "filtering_regular_users" {
  description = "A map of regular users."
  value       = { for k, v in local.regular_users : k => v }
}
