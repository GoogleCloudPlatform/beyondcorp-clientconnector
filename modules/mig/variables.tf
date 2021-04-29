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

variable "project_id" {
  description = "The ID of the project where resources will be deployed"
  type        = string
}

variable "prefix" {
  description = "The prefix to prepend resource names with"
  type        = string
}

variable "regions" {
  description = "Map from a valid GCP region to its configuration"
  type = map(object({
    subnetwork_name    = string
    mig_instance_count = number
  }))
}

variable "service_port" {
  description = "Port serving client connections"
  type        = number
}

variable "ia_tag" {
  description = "Tag used to group gateway instances"
  type        = string
}

variable "cert_params" {
  description = "Object containing CA and server certificate parameters"
  type = object({
    ca_cert_pem        = string,
    server_cert_pem    = string,
    server_pk_pem      = string,
    dh_params_pem_file = string
  })
}
