locals {
  prefix = "${var.prefix}-vpc" # vpc raw version not the iks version
  tags = [
    "prefix:${local.prefix}",
    # lower(replace("dir:${abspath(path.root)}", "/", "_")),
  ]

  zones    = var.zones
  cidr_vpc = "10.0.0.0/8"
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
  name                      = local.prefix
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

# create subnet, VSI, NLB, ... in each zone
module "zone" {
  for_each  = ibm_is_vpc_address_prefix.cloud
  source    = "./zone_tf"
  name      = "${local.prefix}-${each.value.zone}"
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

locals {
  origin_name_ip = { for zone_id, zone in module.zone : zone.name => zone.lb.public_ips[0] }
}

module "cis" {
  source         = "../modules_tf/cis"
  cis_name       = var.cis_name
  domain_name    = var.domain_name
  origin_name_ip = local.origin_name_ip
  glb_name       = "${local.prefix}.${var.domain_name}"
}

output "cis_glb" {
  value = module.cis.global_load_balancer.name
}

output "nlbs" {
  value = local.origin_name_ip
}
output "test_curl_glb" {
  value = <<-EOT
    curl ${module.cis.global_load_balancer.name}/instance
  EOT
}
output "test_curl_nlbs" {
  value = [for name, ip in local.origin_name_ip : <<-EOT
    curl ${ip}/instance;# ${name}
  EOT
  ]
}
