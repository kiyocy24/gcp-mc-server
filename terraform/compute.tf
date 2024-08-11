module "gce-container" {
  source           = "terraform-google-modules/container-vm/google"
  version          = "~> 2.0"
  cos_image_family = "stable"
  restart_policy   = "Always"

  container = {
    image = "docker.io/itzg/minecraft-server"
    env = [
      {
        name  = "TYPE"
        value = var.server_type
      },
      {
        name  = "VERSION"
        value = var.server_version
      },
      {
        name  = "EULA"
        value = "true"
      },
    ]
  }
}

resource "google_compute_instance" "mc_server" {
  name         = "mc-server"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = var.network_tags

  boot_disk {
    initialize_params {
      type  = "pd-ssd" // https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance#type
      size  = 100
      image = module.gce-container.source_image
    }
  }

  network_interface {
    network = "default"
    access_config {} // Ephemeral public ip
  }

  // Logging
  metadata = {
    gce-container-declaration = module.gce-container.metadata_value
    google-logging-enabled    = "true"
    google-monitoring-enabled = "true"
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_firewall" "mc_rule" {
  name    = "minecraft"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["25565"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = var.network_tags
}
