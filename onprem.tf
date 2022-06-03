locals {
  onprem_prefix = "${var.prefix}-onprem"
  onprem_name   = local.onprem_prefix

  DNS_SERVER_IPS   = join(" ", ibm_dns_custom_resolver.cloud.locations.*.dns_server_ip)
  onprem_config    = <<-EOT
    DNS_SERVER_IPS="${local.DNS_SERVER_IPS}"
    # call main function
    main
  EOT
  onprem_user_data = <<-EOT
    ${file("${path.module}/user_data_onprem.sh")}
    ${local.onprem_config}
  EOT
}
resource "ibm_is_vpc" "onprem" {
  name                      = local.onprem_name
  tags                      = local.tags
  resource_group            = data.ibm_resource_group.all_rg.id
  address_prefix_management = "manual"
}

resource "ibm_is_vpc_address_prefix" "onprem" {
  vpc  = ibm_is_vpc.onprem.id
  name = local.onprem_prefix
  zone = local.zone_onprem
  cidr = local.cidr_onprem_0
}

resource "ibm_is_subnet" "onprem" {
  name            = local.onprem_name
  vpc             = ibm_is_vpc.onprem.id
  tags            = local.tags
  zone            = local.zone_onprem
  ipv4_cidr_block = ibm_is_vpc_address_prefix.onprem.cidr
}
resource "ibm_is_security_group" "onprem" {
  name           = local.onprem_name
  vpc            = ibm_is_vpc.onprem.id
  resource_group = data.ibm_resource_group.all_rg.id
}

resource "ibm_is_security_group_rule" "onprem_inbound_all" {
  group     = ibm_is_security_group.onprem.id
  direction = "inbound"
}
resource "ibm_is_security_group_rule" "onprem_outbound_all" {
  group     = ibm_is_security_group.onprem.id
  direction = "outbound"
}
resource "ibm_is_instance" "onprem" {
  name           = local.onprem_name
  vpc            = ibm_is_vpc.onprem.id
  image          = data.ibm_is_image.os.id
  profile        = local.profile
  zone           = ibm_is_subnet.onprem.zone
  keys           = [data.ibm_is_ssh_key.sshkey.id]
  resource_group = data.ibm_resource_group.all_rg.id

  primary_network_interface {
    subnet          = ibm_is_subnet.onprem.id
    security_groups = [ibm_is_security_group.onprem.id]
  }
  user_data = local.onprem_user_data
}
resource "ibm_is_floating_ip" "onprem" {
  name           = local.onprem_name
  target         = ibm_is_instance.onprem.primary_network_interface[0].id
  resource_group = data.ibm_resource_group.all_rg.id
}

resource "ibm_tg_gateway" "onprem" {
  name           = local.onprem_name
  location       = var.region
  global         = true
  resource_group = data.ibm_resource_group.all_rg.id
}

resource "ibm_tg_connection" "onprem" {
  gateway      = ibm_tg_gateway.onprem.id
  network_type = "vpc"
  name         = "onprem"
  network_id   = ibm_is_vpc.onprem.resource_crn
}

resource "ibm_tg_connection" "cloud" {
  gateway      = ibm_tg_gateway.onprem.id
  network_type = "vpc"
  name         = "cloud"
  network_id   = ibm_is_vpc.cloud.resource_crn
}