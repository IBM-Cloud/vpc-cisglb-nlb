resource "ibm_resource_instance" "dns" {
  name              = "${var.prefix}-dns"
  resource_group_id = data.ibm_resource_group.all_rg.id
  location          = "global"
  service           = "dns-svcs"
  plan              = "standard-dns"
}

resource "ibm_dns_zone" "widgets_com" {
  name        = "widgets.com"
  instance_id = ibm_resource_instance.dns.guid
  description = "this is a description"
  label       = "this-is-a-label"
}

resource "ibm_dns_permitted_network" "cloud" {
  instance_id = ibm_resource_instance.dns.guid
  zone_id     = ibm_dns_zone.widgets_com.zone_id
  vpc_crn     = ibm_is_vpc.cloud.crn
  type        = "vpc"
}

/*
resource "ibm_dns_permitted_network" "onprem" {
  instance_id = ibm_resource_instance.dns.guid
  zone_id     = ibm_dns_zone.widgets_com.zone_id
  vpc_crn     = ibm_is_vpc.onprem.crn
  type        = "vpc"
}
*/

resource "ibm_dns_glb_monitor" "cloud" {
  depends_on     = [ibm_dns_zone.widgets_com]
  name           = var.prefix
  instance_id    = ibm_resource_instance.dns.guid
  description    = "ibm_dns_glb_monitor cloud description"
  interval       = 63
  retries        = 3
  timeout        = 8
  port           = 80
  type           = "HTTP"
  expected_codes = "200"
  path           = "/"
  method         = "GET"
  #expected_body  = "alive"
  #headers {
  #  name  = "headerName"
  #  value = ["example", "abc"]
  #}
}

# one pool for each nlb, with a health check from all zones
resource "ibm_dns_glb_pool" "cloud" {
  depends_on                = [ibm_dns_zone.widgets_com]
  name                      = var.prefix
  instance_id               = ibm_resource_instance.dns.guid
  description               = "all nlbs"
  enabled                   = true
  healthy_origins_threshold = 1
  dynamic "origins" {
    for_each = module.zone
    content {
      name    = origins.value.zone
      address = origins.value.lb.hostname
      enabled = true
      # description = ""
    }
  }
  monitor = ibm_dns_glb_monitor.cloud.monitor_id
  #notification_channel = "https://mywebsite.com/dns/webhook"
  healthcheck_region  = var.region
  healthcheck_subnets = [for zone_key, zone in module.zone : zone.subnet_dns.resource_crn]
}

resource "ibm_dns_glb" "cloud" {
  name          = "backend"
  enabled       = true
  instance_id   = ibm_resource_instance.dns.guid
  zone_id       = ibm_dns_zone.widgets_com.zone_id
  description   = "ibm_dns_glb description"
  ttl           = 120
  fallback_pool = ibm_dns_glb_pool.cloud.pool_id
  default_pools = [ibm_dns_glb_pool.cloud.pool_id]
  #dynamic "az_pools" {
  #  for_each = module.zone
  #  content {
  #    availability_zone = az_pools.value.zone
  #    pools             = [ibm_dns_glb_pool.cloud[az_pools.key].pool_id]
  #  }
  #}
}

// configure custom resolvers with a minimum of two resolver locations.
resource "ibm_dns_custom_resolver" "cloud" {
  name        = var.prefix
  instance_id = ibm_resource_instance.dns.guid
  description = "onprem uses this resolver to find the glbs and zones"
  enabled     = true
  dynamic "locations" {
    for_each = module.zone
    content {
      subnet_crn = locations.value.subnet_dns.resource_crn
      enabled    = true
    }
  }
}