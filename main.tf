#resource "null_resource" "test" {
#  provisioner "local-exec" {
#    command = "echo ${var.env}"
#  }
#}

module "network" {
  source         = "github.com/rajrgithub/10-tf-module-vpc"
}
