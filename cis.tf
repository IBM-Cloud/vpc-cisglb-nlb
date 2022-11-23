# Define a global load balancer which directs traffic to defined origin pools
# In normal usage different pools would be set for data centers/availability zones and/or for different regions
# Within each availability zone or region we can define multiple pools in failover order

data "ibm_cis" "instance" {
  name = var.cis_name
}

data "ibm_cis_domain" "instance" {
  domain = "ibmom.com"
  cis_id = data.ibm_cis.instance.id
}

resource "ibm_cis_healthcheck" "lb" {
  cis_id = data.ibm_cis.instance.id
  #expected_body  = "alive"
  expected_codes = "200"
  method         = "GET"
  timeout        = 7
  path           = "/health"
  port           = 80
  interval       = 60
  retries        = 3
  description    = "nlb health check"
}

resource "ibm_cis_origin_pool" "instance" {
  cis_id = data.ibm_cis.instance.id
  name   = "cogs-ibmom-pool"
  dynamic "origins" {
    for_each = { for zone_index, zone in module.zone : zone_index => zone }
    content {
      name    = origins.value.name
      address = origins.value.lb.public_ips[0]
      enabled = true
      weight  = floor(1.0 / length(module.zone) * 100) / 100
    }
  }
  description     = "nlbs"
  enabled         = true
  minimum_origins = 1
  check_regions   = ["WEU"]
  monitor         = ibm_cis_healthcheck.lb.id
}

resource "ibm_cis_global_load_balancer" "instance" {
  cis_id           = data.ibm_cis.instance.id
  domain_id        = data.ibm_cis_domain.instance.id
  name             = "cogs.ibmom.com"
  fallback_pool_id = ibm_cis_origin_pool.instance.id
  default_pool_ids = [ibm_cis_origin_pool.instance.id]
  description      = "glb - nlb"
  proxied          = false # todo check
}
