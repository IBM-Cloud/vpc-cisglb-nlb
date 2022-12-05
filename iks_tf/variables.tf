# variables - see template.local.env for the required variables

variable "prefix" {
  description = "Resources created will be named: prefix-vpc or prefix-iks."
  default     = "glbnlb"
}
variable "resource_group_name" {
  description = "Resource group that will contain all the resources created, try: ibmcloud resource groups"
}

variable "cis_name" {
  description = "IBM Cloud Internet Services name, try: ibmcloud cis instances"
}
variable "domain_name" {
  description = "IBM Cloud Internet Services domain name like example.com, try: ibmcloud cis domains"
}

variable "region" {
  description = "Region for all resources, try: ibmcloud is regions."
  default     = "us-south"
}

variable "instances" {
  description = "number of pods per deployment in zone connected to the NLB"
  default     = 2
}

variable "zones" {
  description = "Number of zones to create"
  default     = 2
}
