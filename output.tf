output "script_cloud" {
  value = templatefile("${path.module}/script.tftpl", {
    zones              = module.zone
    dns_glb            = ibm_dns_glb.cloud
    floating_ip_onprem = ibm_is_floating_ip.onprem
    dns_custom_resolver = ibm_dns_custom_resolver.cloud
  })
}