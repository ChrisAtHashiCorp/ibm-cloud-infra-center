data "hcp_packer_artifact" "ddr-rhel" {
  bucket_name   = "ddr-rhel"
  channel_name  = "production"
  platform      = "openstack"
  region        = "fiservdc"
}

data "openstack_compute_flavor_v2" "size" {
  name = "tiny"
}

data "openstack_networking_network_v2" "network" {
  name = "StLeoLAN75"
}

resource "random_id" "instance_suffix" {
  byte_length = 3
  keepers = {
    # Any changes to these values will generate a new ID
    image_id  = data.hcp_packer_artifact.ddr-rhel.external_identifier
    flavor_id = data.openstack_compute_flavor_v2.size.id
    network   = data.openstack_networking_network_v2.network.name
    # Add other fields that should trigger a new instance when changed
  }
}

resource "openstack_compute_instance_v2" "instance_rhl_wxk" {
  name      = "${var.project}${var.environment}${var.instance_purpose}${random_id.instance_suffix.hex}"
  image_id  = data.hcp_packer_artifact.ddr-rhel.external_identifier
  flavor_id = data.openstack_compute_flavor_v2.size.id
  network {
    name = "${data.openstack_networking_network_v2.network.name}"
  }
  availability_zone = var.availability_zone

  connection {
    type     = "ssh"
    user     = "root"
    password = var.root_password
    host     = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "subscription-manager register --username ${var.rhsat_user} --password ${var.rhsat_pass}",
    ]
  }

  provisioner "local-exec" {
    inline = [
      "ansible-playbook -u root -i ${self.ipv4_address} --private-key ${var.pvt_key} -e pub_key=${var.pub_key} DO-ALL-THE-THINGS.yml ADD-ME-TO-AAP.yml"
    ]
  }
}
