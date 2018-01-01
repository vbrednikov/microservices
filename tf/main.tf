provider "google" {
  project = "${var.project}"
  region  = "${var.region}"
}

# this doesn't work for unknown reason
# resource "google_compute_address" "ui_ingress_lb" {
#   name = "ui-ingress-lb"
#   region = "europe-west1"
# }


resource "google_container_cluster" "reddit" {
  name               = "marcellus-wallace"
  zone               = "europe-west1-b"
  initial_node_count = 3
  # enable abac for gitlab
  enable_legacy_abac = true

  min_master_version = "1.8.3-gke.0"

  addons_config {
    kubernetes_dashboard {
      disabled = false
    }
  }
  master_auth {
    username = "landocalrissian"
    password = "kdfnar338sjjcn38"
  }

  node_config {
    disk_size_gb = "${var.disk_size_gb}"
    machine_type = "n1-standard-1"
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials marcellus-wallace --zone ${var.zone}  --project ${var.project}"
  }
}

resource "google_container_node_pool" "bigpool" {
  name               = "bigpool"
  zone               = "${var.zone}"
  cluster            = "${google_container_cluster.reddit.name}"
  node_count = 1
  node_config {
    disk_size_gb = "${var.disk_size_gb}"
    machine_type = "n1-standard-2"
  }
}

# resource "google_compute_disk" "reddit-mongo" {
#   name  = "reddit-mongo-disk"
#   zone  = "${var.zone}"
#   size = 25
# }

#provider "kubernetes" {}

provider "kubernetes" {
  host     = "https://${google_container_cluster.reddit.endpoint}"
  username = "landocalrissian"
  password = "kdfnar338sjjcn38"

  client_certificate     = "${base64decode(google_container_cluster.reddit.master_auth.0.client_certificate)}"
  client_key             = "${base64decode(google_container_cluster.reddit.master_auth.0.client_key)}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.reddit.master_auth.0.cluster_ca_certificate)}"
}

resource "kubernetes_namespace" "dev" {
#  depends_on=["google_container_cluster.reddit"]
  metadata {
    name = "dev"
  }
}

resource "kubernetes_secret" "ui_ingress_cert" {
  type = "kubernetes.io/tls"
  depends_on=["kubernetes_namespace.dev"]

  metadata {
    name      = "ui-ingress"
    namespace = "dev"
  }

  data {
    tls.crt = "${tls_locally_signed_cert.ingress_cert.cert_pem}"
    tls.key = "${tls_private_key.ingress.private_key_pem}"
  }
}
