########### Variables ###########
variable "hcloud_token" {}
variable "username" {}
variable "sshkey_location" {}
variable "backup_location" {}

########### Data ###########
data "template_file" "sshkey" {
  template = file(var.sshkey_location)
}

data "template_file" "backup" {
  template = file(var.backup_location)
}

########### Modules ###########
module "mcserver"{
  source = "./mcserver"
  hcloud_token = var.hcloud_token
  username = var.username
  sshkey = data.template_file.sshkey.rendered
  copy_mods = true
  modpack_name = "Valhelsia_SERVER-3.0.21.zip"
  restore_local_backup = false
  restore_point = data.template_file.backup.rendered
}

########### Output ###########
output "server_ipv4" {
  value = module.mcserver.server_ipv4
}

output "server_ipv6" {
  value = module.mcserver.server_ipv6
}