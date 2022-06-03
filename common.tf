locals {
  tags = [
    "prefix:${var.prefix}",
    # lower(replace("dir:${abspath(path.root)}", "/", "_")),
  ]

  # on prem 
  cidr_onprem   = "192.168.0.0/16"
  cidr_onprem_0 = cidrsubnet(local.cidr_onprem, 8, 0)
  zone_onprem   = "${var.region}-1"

  # cloud
  # must be 2 or 3 zones - for dns resolver locations
  zones      = 2
  cidr_cloud = "10.0.0.0/8"
  # number of instances in each zone
  instances = 1
  # one vpc
  cidr_vpc = cidrsubnet(local.cidr_cloud, 8, 0)
  cidr_zones = { for zone in range(local.zones) : zone => {
    zone = "${var.region}-${zone + 1}"
    cidr = cidrsubnet(local.cidr_vpc, 8, zone),
  } }

  cloud_image_name = "ibm-ubuntu-20-04-3-minimal-amd64-2"
  profile          = "cx2-2x4"
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

