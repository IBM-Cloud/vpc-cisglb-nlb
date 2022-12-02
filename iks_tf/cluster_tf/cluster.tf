variable "tags" {}
variable "prefix" {}
variable "cidr_zones" {}
variable "worker_count" {}
variable "flavor" {}
variable "resource_group_id" {}

resource "ibm_is_vpc" "cloud" {
  name                      = var.prefix
  tags                      = var.tags
  resource_group            = var.resource_group_id
  address_prefix_management = "manual"
}

resource "ibm_is_vpc_address_prefix" "zone" {
  for_each = var.cidr_zones
  vpc      = ibm_is_vpc.cloud.id
  name     = each.value.zone
  zone     = each.value.zone
  cidr     = each.value.cidr
}

resource "ibm_is_public_gateway" "example" {
  for_each       = ibm_is_vpc_address_prefix.zone
  name           = each.value.name
  resource_group = var.resource_group_id
  vpc            = ibm_is_vpc.cloud.id
  zone           = each.value.zone
}

resource "ibm_is_subnet" "zone" {
  for_each        = ibm_is_vpc_address_prefix.zone
  name            = each.value.name
  resource_group  = var.resource_group_id
  vpc             = ibm_is_vpc.cloud.id
  zone            = each.value.zone
  ipv4_cidr_block = each.value.cidr
  public_gateway  = ibm_is_public_gateway.example[each.key].id
}

resource "ibm_container_vpc_cluster" "cluster" {
  name   = var.prefix
  vpc_id = ibm_is_vpc.cloud.id
  # todo kube_version      = var.kube_version
  flavor            = var.flavor
  worker_count      = var.worker_count
  resource_group_id = var.resource_group_id

  dynamic "zones" {
    for_each = ibm_is_subnet.zone
    content {
      subnet_id = zones.value.id
      name      = zones.value.name
    }
  }
}

output "id" {
  value = ibm_container_vpc_cluster.cluster.id
}
