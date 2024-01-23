module "gce-container" {
  source           = "terraform-google-modules/container-vm/google"
  version          = "~> 3.1"
  cos_image_family = "stable"
  restart_policy   = "Always"

  container = {
    image = "docker.io/thijsvanloef/palworld-server-docker"
    env = [
      {
        name  = "PLAYERS"
        value = "16"
      },
      {
        name  = "PORT"
        value = "8211"
      },
      {
        name  = "MULTITHREADING"
        value = "false"
      },
    ]
    volumeMounts = [
      {
        mountPath = "/Palworld"
        name      = "palworld-volume"
        readOnly  = false
      },
    ]
  }

  volumes = [
    {
      name = "palworld-volume"

      gcePersistentDisk = {
        pdName = "palworld-disk"
        fsType = "ext4"
      }
    },
  ]
}

resource "google_compute_instance" "pw_server" {
  name         = "pw-server"
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

resource "google_compute_firewall" "pw_rule" {
  name    = "palworld"
  network = "default"
  allow {
    protocol = "udp"
    ports    = ["8211"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = var.network_tags
}
