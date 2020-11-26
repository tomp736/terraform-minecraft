########### Variables ###########
variable "hcloud_token" {}
variable "username" {}
variable "sshkey" {}
variable "modpack_name" {}
variable "copy_mods" {
  description = "If set to true, restore backup during provision"
  type        = bool
}
variable "restore_point" {}
variable "restore_local_backup" {
  description = "If set to true, restore backup during provision"
  type        = bool
}

########### Data ###########
data "template_file" "cloud-init-yaml" {
  template = file("${path.module}/cloud-init.yaml")
  vars = {
    username = var.username
    sshkey-admin = var.sshkey
  }
}

########### Providers ###########
provider "hcloud" {
  token = var.hcloud_token
}

########### Server ###########
resource "hcloud_volume_attachment" "main" {
  volume_id = hcloud_volume.mcdata.id
  server_id = hcloud_server.mcserver.id

  provisioner "file" {
    source        = "mcserver/setup_volume.sh"
    destination   = "/tmp/setup_volume.sh"
    connection {
      host        = hcloud_server.mcserver.ipv4_address
      user        = var.username
      private_key = file("~/.ssh/id_rsa")
    }
  }

  provisioner "file" {
    source        = "mcserver/manage.sh"
    destination   = "/tmp/manage.sh"
    connection {
      host        = hcloud_server.mcserver.ipv4_address
      user        = var.username
      private_key = file("~/.ssh/id_rsa")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup_volume.sh",
      "sudo /tmp/setup_volume.sh \"/dev/sdb\" \"/mcdata\"",
      "rm /tmp/setup_volume.sh",
      "sudo mv /tmp/manage.sh /mcdata/manage.sh",
      "sudo chown mc:admin /mcdata/manage.sh",
      "sudo chmod +x /mcdata/manage.sh"
    ]
    connection {
      host        = hcloud_server.mcserver.ipv4_address
      user        = var.username
      private_key = file("~/.ssh/id_rsa")
    }
  }
}

resource "hcloud_server" "mcserver" {
  name = "mc-mod-server"
  location = "fsn1"
  image = "ubuntu-18.04"
  backups = true
  server_type = "cx31"
  user_data = data.template_file.cloud-init-yaml.rendered

  ##### emit ipv4 for scripts ######
  provisioner "local-exec" {
    command = "echo ${hcloud_server.mcserver.ipv4_address} > .serverassets/etc/ipv4_address"
  }
}

resource "null_resource" "restore_backups" {
  count = var.restore_local_backup ? 1 : 0

  provisioner "file" {
    source        = ".serverassets/backups/last_backup"
    destination   = "/mcdata/backups/last_backup"
    connection {
      host        = hcloud_server.mcserver.ipv4_address
      user        = var.username
      private_key = file("~/.ssh/id_rsa")
    }
  }

  provisioner "file" {
    source        = ".serverassets/backups/${var.restore_point}"
    destination   = "/mcdata/backups"
    connection {
      host        = hcloud_server.mcserver.ipv4_address
      user        = var.username
      private_key = file("~/.ssh/id_rsa")
    }
  }
  depends_on = [hcloud_volume_attachment.main]
}

resource "null_resource" "copy_mods" {
  count = var.copy_mods ? 1 : 0
  provisioner "file" {
    source        = ".serverassets/modpacks/Valhelsia_SERVER-3.0.21.zip"
    destination   = "/mcdata/modpacks/Valhelsia_SERVER-3.0.21.zip"
    connection {
      host        = hcloud_server.mcserver.ipv4_address
      user        = var.username
      private_key = file("~/.ssh/id_rsa")
    }
  }
  depends_on = [hcloud_volume_attachment.main]
}

resource "hcloud_volume" "mcdata" {
  location = "fsn1"
  name = "mc-mod-data"
  size = 10
}
########### Output ###########
output "server_ipv4" {
  value = hcloud_server.mcserver.ipv4_address
}
output "server_ipv6" {
  value = hcloud_server.mcserver.ipv6_address
}