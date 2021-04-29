/**
 * Copyright 2021 Google LLC
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

# Creates instance templates for use by the MIG instances.
resource "google_compute_instance_template" "iatpl" {
  project     = var.project_id
  for_each    = var.regions
  name_prefix = "${var.prefix}-${each.key}-iatpl"
  description = "Instance template for ${each.key}"

  machine_type = "n1-standard-1"
  region       = each.key

  # Uses the default service account provisioned for the VM. Recommended.
  service_account {
    scopes = ["cloud-platform"]
  }

  disk {
    boot         = true
    source_image = "projects/cos-cloud/global/images/family/cos-stable"
    disk_size_gb = "50"
    disk_type    = "pd-standard"
  }

  network_interface {
    subnetwork = var.regions[each.key].subnetwork_name
  }

  metadata = {
    # Stackdriver logging and monitoring.
    google-logging-enabled    = "true"
    google-monitoring-enabled = "true"
    user-data = templatefile("${path.module}/../templates/cloud_init.tpl", {
      ca_pem          = var.cert_params.ca_cert_pem
      server_cert_pem = var.cert_params.server_cert_pem
      server_pk_pem   = var.cert_params.server_pk_pem
      dh_params_pem   = file(var.cert_params.dh_params_pem_file)
    })
  }

  tags = [
    var.ia_tag
  ]

  # Required to send and receive packets with non-matching source or destination
  # IPs (for ex. when using a NAT).
  can_ip_forward = true

  lifecycle {
    create_before_destroy = "true"
  }
}

# Creates a Managed Instance Group (MIG) per-region.
resource "google_compute_region_instance_group_manager" "mig" {
  project            = var.project_id
  for_each           = var.regions
  region             = each.key
  base_instance_name = "${var.prefix}-${each.key}-ia"
  name               = "${var.prefix}-${each.key}-mig"

  version {
    name              = "${var.prefix}-preview"
    instance_template = google_compute_instance_template.iatpl[each.key].self_link
  }

  named_port {
    name = "tcp"
    port = var.service_port
  }

  target_size        = var.regions[each.key].mig_instance_count
  wait_for_instances = true
}
