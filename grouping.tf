variable "grouped_users" {
  type = map(object({
    role = string
  }))
  default = {
    "reader_one" = {
      role = "reader"
    }
    "reader_two" = {
      role = "reader"
    }
    "admin_user" = {
      role = "admin"
    }
    "contributor_one" = {
      role = "contributor"
    }
    "contributor_two" = {
      role = "contributor"
    }
  }
}

locals {
  grouped_users_by_role = {
    # As we expect duplicate roles, we can  use the ellipsis (...)
    # after the value expression to enable grouping by key.
    # The local.grouped_users_by_role expression inverts the input map
    # so that the keys are the role names and the values are usernames,
    # but the expression is in grouping mode (due to the ... after name)
    # and so the result will be a map of lists of string
    for name, user in var.grouped_users : user.role => name...
  }

  # Without the `...` operator, this would fail due to the duplicate key "reader":
  # Error: Two different items produced the key "reader" in this 'for' expression.
  # ungrouped_users_by_role = {
  #   for name, user in var.grouped_users : user.role => name
  # }
}

output "grouped_users_by_role" {
  value = local.grouped_users_by_role
}
