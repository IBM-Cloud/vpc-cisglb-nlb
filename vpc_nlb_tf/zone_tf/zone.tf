locals {
  cidr_zone    = cidrsubnet(var.cidr, 1, 0) # zone subnet for the instances
  cidr_control = cidrsubnet(var.cidr, 1, 1) # rest of the stuff
  cidr_nlb     = cidrsubnet(local.cidr_control, 3, 0)
}
resource "ibm_is_subnet" "zone" {
  name            = var.name
  resource_group  = var.resource_group.id
  vpc             = var.vpc.id
  zone            = var.zone
  ipv4_cidr_block = local.cidr_zone
}
resource "ibm_is_security_group" "zone" {
  name           = "${var.name}-zone"
  vpc            = var.vpc.id
  resource_group = var.resource_group.id
}

resource "ibm_is_security_group_rule" "zone_inbound_all" {
  group     = ibm_is_security_group.zone.id
  direction = "inbound"
}
resource "ibm_is_security_group_rule" "zone_outbound_all" {
  group     = ibm_is_security_group.zone.id
  direction = "outbound"
}
resource "ibm_is_instance" "zone" {
  for_each       = { for index in range(var.instances) : index => "${ibm_is_subnet.zone.name}-${index}" }
  name           = each.value
  image          = var.image.id
  profile        = var.profile
  vpc            = var.vpc.id
  zone           = ibm_is_subnet.zone.zone
  keys           = var.keys
  user_data      = <<-EOT
    ${var.user_data}
    echo ${each.value} > /var/www/html/instance
    echo ${ibm_is_subnet.zone.zone} > /var/www/html/health
  EOT
  resource_group = var.resource_group.id

  primary_network_interface {
    subnet          = ibm_is_subnet.zone.id
    security_groups = [ibm_is_security_group.zone.id]
  }
}
resource "ibm_is_floating_ip" "zone" {
  for_each       = ibm_is_instance.zone
  name           = each.value.name
  target         = each.value.primary_network_interface[0].id
  resource_group = var.resource_group.id
}
resource "ibm_is_subnet" "zone_nlb" {
  name            = "${var.name}-nlb"
  resource_group  = var.resource_group.id
  vpc             = var.vpc.id
  zone            = var.zone
  ipv4_cidr_block = local.cidr_nlb
}
resource "ibm_is_lb" "zone" {
  name           = var.name
  resource_group = var.resource_group.id
  subnets        = [ibm_is_subnet.zone_nlb.id]
  profile        = "network-fixed"
  type           = "public"
}
resource "ibm_is_lb_listener" "zone" {
  lb           = ibm_is_lb.zone.id
  default_pool = ibm_is_lb_pool.zone.id
  protocol     = "tcp"
  port         = 80
}

resource "ibm_is_lb_pool" "zone" {
  name                     = var.name
  lb                       = ibm_is_lb.zone.id
  algorithm                = "round_robin"
  protocol                 = "tcp"
  session_persistence_type = "source_ip"
  health_delay             = 10 # Interval
  health_retries           = 2  # Max retries
  health_timeout           = 5  # Timeout
  health_type              = "http"
  health_monitor_url       = "/health"
  #health_monitor_port    = 80
}
resource "ibm_is_lb_pool_member" "zone" {
  for_each  = ibm_is_instance.zone
  lb        = ibm_is_lb.zone.id
  pool      = element(split("/", ibm_is_lb_pool.zone.id), 1)
  port      = 80
  target_id = each.value.id
  weight    = 60
}
