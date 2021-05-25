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

# Create a storage bucket to store customer's client parameters.
resource "google_storage_bucket" "bucket" {
  project  = var.producer_project_id
  name     = "${var.prefix}-${var.customer_id}-bucket"
  location = "US"

  # Deleting bucket will delete all contained objects.
  force_destroy = true

  # Access is only governed by IAM policies. Disables other ACL controls.
  uniform_bucket_level_access = true
}

# Create object within the bucket containing the client parameters in JSON
# format.
resource "google_storage_bucket_object" "client_params" {
  name         = "${var.prefix}-client-params.json"
  bucket       = google_storage_bucket.bucket.name
  content_type = "application/json"

  # Params to be made available to OpenVPN client.
  content = jsonencode({
    "connections" = [
      for ip in setunion(
        var.client_params.remote_ipv4_addresses,
        var.client_params.remote_ipv6_addresses
      ) :
      {
        "remote" = {
          "address"  = ip
          "port"     = var.service_port
          "protocol" = "TCP"
        }
      }
    ],
    "routes" = [
      for cidr in var.client_params.private_subnets :
      {
        "address" = cidrhost(cidr, 0)
        "mask"    = cidrnetmask(cidr)
      }
    ],
    "server_verification" = {
      "ca" = {
        "ca_pem" = [var.client_params.ca_cert_pem]
      }
    }
  })
}
