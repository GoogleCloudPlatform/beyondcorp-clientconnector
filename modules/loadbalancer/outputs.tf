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

output "ipv4_addresses" {
  description = "Set of IPv4 addresses of the external load balancer"
  value       = [google_compute_global_address.ipv4_addr.address]
}

output "ipv6_addresses" {
  description = "Set of IPv6 addresses of the external load balancer. Empty if IPv6 support is not enabled"
  value       = var.enable_ipv6_forwarding ? [google_compute_global_address.ipv6_addr[0].address] : []
}
