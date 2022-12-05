locals {
  prefix = "${var.prefix}-iks" # iks not vpc raw
  tags = [
    "prefix:${local.prefix}",
    lower(replace("dir:${abspath(path.root)}", "/", "_")),
  ]

  zones    = var.zones
  cidr_vpc = "10.0.0.0/8"
  cidr_zones = { for zone in range(local.zones) : zone => {
    zone = "${var.region}-${zone + 1}"
    cidr = cidrsubnet(local.cidr_vpc, 8, zone),
  } }
}

data "ibm_resource_group" "all_rg" {
  name = var.resource_group_name
}

# IKS Cluster ---------------------------------------------------------
module "cluster" {
  source     = "./cluster_tf"
  tags       = local.tags
  prefix     = local.prefix
  cidr_zones = local.cidr_zones
  # todo
  #worker_count      = local.zones
  worker_count      = 1
  flavor            = "cx2.2x4"
  resource_group_id = data.ibm_resource_group.all_rg.id
}


data "ibm_container_cluster_config" "cluster" {
  cluster_name_id   = module.cluster.id
  resource_group_id = data.ibm_resource_group.all_rg.id
  admin             = true
  config_dir        = path.module
}

provider "kubernetes" {
  config_path = data.ibm_container_cluster_config.cluster.config_file_path
}


# Kubernetes Resources ---------------------------------------------------------
locals {
  pythonProgram = <<-EOT
    from http.server import BaseHTTPRequestHandler, HTTPServer
    from http import HTTPStatus
    import os

    hostName = "0.0.0.0"
    serverPort = _PORT_
    return_str = "_ZONE_ "
    env_host_name = os.environ["HOSTNAME"]

    class MyServer(BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(HTTPStatus.OK)
            self.end_headers()
            self.wfile.write(bytes(return_str + env_host_name + "\n", "utf-8"))

    webServer = HTTPServer((hostName, serverPort), MyServer)
    print("Server started http://%s:%s" % (hostName, serverPort))
    webServer.serve_forever()
  EOT
}

resource "kubernetes_deployment" "zone" {
  for_each = local.cidr_zones
  metadata {
    name = "cogs-${each.key}"
    labels = {
      app = "cogs"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "cogs"
      }
    }

    replicas = var.instances

    template {
      metadata {
        labels = {
          app = "cogs"
        }
      }

      spec {
        node_selector = {
          "ibm-cloud.kubernetes.io/zone" = each.value.zone
        }
        container {
          image   = "python:3"
          name    = "cogs"
          command = ["python"]
          args    = ["-c", replace(replace(local.pythonProgram, "_ZONE_", each.value.zone), "_PORT_", 80)]

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "zone" {
  for_each = local.cidr_zones
  timeouts {
    create = "60m"
  }
  metadata {
    name = "load-balancer-${each.value.zone}"
    annotations = {
      "service.kubernetes.io/ibm-load-balancer-cloud-provider-enable-features" = "nlb"
      "service.kubernetes.io/ibm-load-balancer-cloud-provider-ip-type"         = "public"
      "service.kubernetes.io/ibm-load-balancer-cloud-provider-zone"            = each.value.zone
    }
  }
  spec {
    type                    = "LoadBalancer"
    external_traffic_policy = "Local"
    selector = {
      app = "cogs"
    }
    port {
      name     = "http"
      protocol = "TCP"
      port     = 80
    }
    #port {
    #  name     = "https"
    #  protocol = "TCP"
    #  port     = 443
    #}
  }
}

# ICS GLB ---------------------------------------------------------
locals {
  origin_name_ip = { for service_id, service in kubernetes_service.zone : service.metadata[0].name => service.status[0].load_balancer[0].ingress[0].ip }
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
output "test_kubectl" {
  value = <<-EOT
    # choose one:
    export KUBECONFIG=${data.ibm_container_cluster_config.cluster.config_file_path} ;# env var
    ibmcloud cs cluster config --cluster ${data.ibm_container_cluster_config.cluster.cluster_name_id} ;# cluster config via cluster id
    # try these:
    kubectl get deployments
    kubectl get services
  EOT
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
