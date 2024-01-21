locals {
  deploy_if_map_value_is_true = {
    deploy_true = {
      name    = "Deploy Me"
      enabled = true
    }
    deploy_false = {
      name    = "Do Not Deploy Me"
      enabled = false
    }
  }
}

resource "null_resource" "deploy_if_map_value_is_true" {

  for_each = {
    for k, v in local.deploy_if_map_value_is_true :
    k => v if v.enabled == true
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo -e "\n***Hello, ${each.value.name}!***\n"
    EOT
  }

}
