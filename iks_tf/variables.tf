# variables - see template.local.env for the required variables

variable "prefix" {
  description = "resources created will be named: $${prefix}vpc-pubpriv, vpc name will be $${prefix} or will be defined by vpc_name"
  default     = "glbnlb"
}

variable "resource_group_name" {
  description = "Resource group that will contain all the resources created by the script."
}

variable "cis_name" {
  description = "IBM Cloud Internet Services name. Try command: ibmcloud cis instances"
}
variable "domain_name" {
  description = "IBM Cloud Internet Services domain name like example.com, try command: ibmcloud cis domains"
}

variable "region" {
  description = "Availability zone that will have the resources deployed to.  To obtain a list of availability zones you can run the ibmcloud cli: ibmcloud is regions."
  default     = "us-south"
}

variable "zones" {
  description = "number of zones to create"
  default     = 2
}
