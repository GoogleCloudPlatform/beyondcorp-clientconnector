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

#
# Variables fulfilled by user.
#
variable "credentials_file" {
  description = "Key file (JSON) of the service account used to authenticate"
  type        = string
}

variable "project_id" {
  description = "The ID of the project where resources will be deployed"
  type        = string
}

variable "customer_id" {
  description = "The Google Workspace customer ID. See https://support.google.com/cloudidentity/answer/10070793"
  type        = string
}

variable "vpc_network" {
  description = "The VPC network where resources will be deployed. Should not have auto subnetting enabled"
  type        = string
}

variable "regions" {
  description = "Map from a valid GCP region to its configuration"
  type = map(object({
    subnetwork_cidr    = string
    mig_instance_count = number
  }))

  validation {
    # Basic sanity check to enforce CIDR notation.
    # Will not detect cases wrong inputs like 10.1.1.1/8.
    # Only supports IPv4 currently. IPv6 support will be added.
    condition = length([
      for v in values(var.regions) : true
      if can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/([0-9]|[1-2][0-9]|3[0-2])$", v.subnetwork_cidr))
    ]) == length(var.regions)
    error_message = "All region subnets must be in CIDR notation."
  }
}

variable "private_subnets" {
  description = "List of destination subnets (CIDR notation), user traffic to which shall pass through gateway."
  type        = set(string)

  validation {
    # Basic sanity check to enforce CIDR notation.
    # Will not detect cases wrong inputs like 10.1.1.1/8.
    # Only supports IPv4 currently. IPv6 support will be added.
    condition = length([
      for subnet in var.private_subnets : true
      if can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/([0-9]|[1-2][0-9]|3[0-2])$", subnet))
    ]) == length(var.private_subnets)
    error_message = "All subnets must be in CIDR notation."
  }
}

variable "dh_params_pem_file" {
  description = "PEM file containing the Diffie-Hellman parameters. Recommended key length is 2048 bits"
  type        = string
}
