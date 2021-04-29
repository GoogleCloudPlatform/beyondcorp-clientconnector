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

variable "vpc_network" {
  description = "The VPC network where resources will be deployed. Should not have auto subnetting enabled"
  type        = string
}

variable "service_port" {
  description = "Port serving client connections"
  type        = number
}

variable "ia_tag" {
  description = "Tag used to group gateway instances"
  type        = string
}

variable "backend_ia_groups" {
  description = "List of instance groups serving as the backend service"
  type        = list(string)
}

variable "enable_ipv6_forwarding" {
  description = "Whether to setup IPv6 forwarding"
  type        = bool
  default     = false
}
