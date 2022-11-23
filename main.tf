locals {
  tags = [
    "prefix:${var.prefix}",
    # lower(replace("dir:${abspath(path.root)}", "/", "_")),
  ]

  zones      = var.zones
  cidr_cloud = "10.0.0.0/8"
  cidr_vpc   = cidrsubnet(local.cidr_cloud, 8, 0)
  cidr_zones = { for zone in range(local.zones) : zone => {
    zone = "${var.region}-${zone + 1}"
    cidr = cidrsubnet(local.cidr_vpc, 8, zone),
  } }
  # number of instances in each zone
  instances        = var.instances
  cloud_image_name = "ibm-ubuntu-20-04-3-minimal-amd64-2"
  profile          = "cx2-2x4"

  user_data = <<-EOT
  #!/bin/bash
  set -x
  export DEBIAN_FRONTEND=noninteractive
  apt -qq -y update < /dev/null
  apt -qq -y install nginx npm < /dev/null
  EOT
}

data "ibm_resource_group" "all_rg" {
  name = var.resource_group_name
}

data "ibm_is_ssh_key" "sshkey" {
  name = var.ssh_key_name
}

data "ibm_is_image" "os" {
  name = local.cloud_image_name
}


resource "ibm_is_vpc" "cloud" {
  name                      = var.prefix
  tags                      = local.tags
  resource_group            = data.ibm_resource_group.all_rg.id
  address_prefix_management = "manual"
}

resource "ibm_is_vpc_address_prefix" "cloud" {
  for_each = local.cidr_zones
  vpc      = ibm_is_vpc.cloud.id
  name     = each.value.zone
  zone     = each.value.zone
  cidr     = each.value.cidr
}

module "zone" {
  for_each  = ibm_is_vpc_address_prefix.cloud
  source    = "./modules/zone"
  name      = "${var.prefix}-${each.value.zone}"
  zone      = each.value.zone
  cidr      = each.value.cidr
  instances = local.instances
  profile   = local.profile
  keys      = [data.ibm_is_ssh_key.sshkey.id]
  vpc = {
    id = ibm_is_vpc.cloud.id
  }
  resource_group = {
    id = data.ibm_resource_group.all_rg.id
  }
  image = {
    id = data.ibm_is_image.os.id
  }
  user_data = local.user_data
}
