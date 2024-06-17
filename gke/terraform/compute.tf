/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "google_service_account" "default" {
  count        = var.create_bastion ? 1 : 0
  project      = var.google_cloud_k8s_project
  account_id   = "custom-compute-sa"
  display_name = "Custom SA for VM Instance"
}

resource "google_compute_instance" "default" {
  count        = var.create_bastion ? 1 : 0
  project      = var.google_cloud_k8s_project
  name         = "bastion"
  machine_type = "n2-standard-2"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = "100"
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    network            = local.network_name
    subnetwork         = local.subnet_name
    subnetwork_project = var.google_cloud_k8s_project

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = <<-EOF
  sudo apt install postgresql-client -y
  sudo apt install dnsutils -y
  EOF
  }

  service_account {
    email  = google_service_account.default[count.index].email
    scopes = ["cloud-platform"]
  }

  depends_on = [module.gcp_network]
}
