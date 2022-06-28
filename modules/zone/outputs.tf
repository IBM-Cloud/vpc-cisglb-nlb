output "zone" {
  value = var.zone
}
output "name" {
  value = var.name
}
output "instances" {
  value = ibm_is_instance.zone
}
output "floating_ip" {
  value = ibm_is_floating_ip.zone
}
output "lb" {
  value = ibm_is_lb.zone
}
output "lb_listener" {
  value = ibm_is_lb_listener.zone
}
output "lb_pool" {
  value = ibm_is_lb_pool.zone
}
output "lb_pool_member" {
  value = ibm_is_lb_pool_member.zone
}
output "subnet" {
  value = ibm_is_subnet.zone
}
output "subnet_nlb" {
  value = ibm_is_subnet.zone_nlb
}
output "subnet_dns" {
  value = ibm_is_subnet.zone_dns
}