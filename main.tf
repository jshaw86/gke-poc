variable "region1_cluster_name" {
  default = "tf-region1"
}

variable "region1" {
  default = "us-west1"
}

variable "network_name" {
  default = "tf-gke-multi-region"
}

provider "google" {
  region = "${var.region1}"
}

data "google_client_config" "current" {}

resource "google_compute_network" "default" {
  name                    = "${var.network_name}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "region1" {
  name          = "${var.network_name}"
  ip_cidr_range = "10.126.0.0/20"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.region1}"
}

module "cluster1" {
  source       = "./gke-regional"
  region       = "${var.region1}"
  cluster_name = "${var.region1_cluster_name}"
  tags         = ["tf-gke-region1"]
  network      = "${google_compute_subnetwork.region1.network}"
  subnetwork   = "${google_compute_subnetwork.region1.name}"
}

provider "kubernetes" {
  alias                  = "cluster1"
  host                   = "${module.cluster1.endpoint}"
  token                  = "${data.google_client_config.current.access_token}"
  client_certificate     = "${base64decode(module.cluster1.client_certificate)}"
  client_key             = "${base64decode(module.cluster1.client_key)}"
  cluster_ca_certificate = "${base64decode(module.cluster1.cluster_ca_certificate)}"
}

/*
module "glb" {
  source            = "GoogleCloudPlatform/lb-http/google"
  version           = "1.0.10"
  name              = "gke-multi-regional"
  target_tags       = ["tf-gke-region1", "tf-gke-region2"]
  firewall_networks = ["${google_compute_network.default.name}"]

  backends = {
    "0" = [
      {
        group = "${element(module.cluster1.instance_groups, 0)}"
      },
      {
        group = "${element(module.cluster1.instance_groups, 1)}"
      },
      {
        group = "${element(module.cluster1.instance_groups, 2)}"
      },
    ]
  }

  backend_params = [
    // health check path, port name, port number, timeout seconds.
    "/,http,30000,10",
  ]
}
*/

module "cluster1_named_port_1" {
  source         = "github.com/danisla/terraform-google-named-ports"
  instance_group = "${element(module.cluster1.instance_groups, 0)}"
  name           = "http"
  port           = "30000"
}

output "cluster1-name" {
  value = "${var.region1_cluster_name}"
}

output "cluster1-region" {
  value = "${var.region1}"
}

/*
output "load-balancer-ip" {
  value = "${module.glb.external_ip}"
}
*/

