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

  min_master_version = "1.8.3-gke.0"

  addons_config {
    kubernetes_dashboard {
      disabled = false
    }
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
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "google_compute_disk" "reddit-mongo" {
  name  = "reddit-mongo-disk"
  zone  = "${var.zone}"
  size = 25
}

provider "kubernetes" {}

resource "kubernetes_namespace" "dev" {
  depends_on=["google_container_cluster.reddit"]
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