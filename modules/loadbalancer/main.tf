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

# Creates TCP load balancer health check to determine if instances are healthy.
resource "google_compute_health_check" "tcp_lb_hc" {
  provider    = google-beta # needed for log_config support
  project     = var.project_id
  name        = "${var.prefix}-tcp-lb-hc"
  description = "Health check via tcp for the backend service"

  timeout_sec = 10
  # Keep this value higher than |timeout_sec|.
  check_interval_sec  = 20
  healthy_threshold   = 2
  unhealthy_threshold = 2

  tcp_health_check {
    # Connection on this port indicates health.
    port = var.service_port
  }

  log_config { enable = true }
}

# Opens firewall to allow ingress from TCP LB health check's IP range.
resource "google_compute_firewall" "allow_tcp_ingress_from_hc_range" {
  name    = "${var.prefix}-allow-tcp-ingress-from-hc"
  project = var.project_id
  network = var.vpc_network

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]

  target_tags = [var.ia_tag]
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = [var.service_port]
  }
}

# Creates backend service for External TCP Proxy Load Balancer.
resource "google_compute_backend_service" "backend_service" {
  project     = var.project_id
  name        = "${var.prefix}-be-service"
  description = "Backend service for the external tcp proxy load balancer."

  # Named backend port that appears in the balanced instance group too.
  port_name = "tcp"
  protocol  = "TCP"
  # Default |load_balancing_scheme| is EXTERNAL.

  # For TCP proxy load balancers, this is an idle timeout.
  timeout_sec   = 19 * 60 * 60 # 19 hours
  health_checks = [google_compute_health_check.tcp_lb_hc.self_link]

  dynamic "backend" {
    for_each = var.backend_ia_groups
    content {
      group = backend.value
      # Using default UTILIZATION balancing mode with 80% max-utilization.
      #
      # Other option is to limit by number of CONNECTIONS. That can be
      # controlled via OVPN server's configuration itself for fine-grain tuning.
    }
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# Creates target proxy for External TCP Proxy Load Balancer.
resource "google_compute_target_tcp_proxy" "tcp_proxy" {
  name            = "${var.prefix}-target-tcp-proxy"
  backend_service = google_compute_backend_service.backend_service.id
}

# Reserves static external IPv4 address for the load balancer.
resource "google_compute_global_address" "ipv4_addr" {
  project = var.project_id
  name    = "${var.prefix}-lb-ip-v4"
}

# Creates global IPv4 forwarding rule for External TCP Proxy Load Balancer.
resource "google_compute_global_forwarding_rule" "fw_rule_ipv4" {
  name        = "${var.prefix}-lb-fw-rule-ipv4"
  ip_protocol = "TCP"
  ip_address  = google_compute_global_address.ipv4_addr.address
  port_range  = var.service_port
  target      = google_compute_target_tcp_proxy.tcp_proxy.id
}

# Reserves static external IPv6 address for the load balancer,
# if IPv6 forwarding is enabled.
resource "google_compute_global_address" "ipv6_addr" {
  count = var.enable_ipv6_forwarding ? 1 : 0

  project    = var.project_id
  name       = "${var.prefix}-lb-ip-v6"
  ip_version = "IPV6"
}

# Creates global IPv6 forwarding rule for External TCP Proxy Load Balancer,
# if IPv6 forwarding is enabled.
resource "google_compute_global_forwarding_rule" "fw_rule_ipv6" {
  count = var.enable_ipv6_forwarding ? 1 : 0

  name        = "${var.prefix}-lb-fw-rule-ipv6"
  ip_protocol = "TCP"
  ip_address  = google_compute_global_address.ipv6_addr[0].address
  port_range  = var.service_port
  target      = google_compute_target_tcp_proxy.tcp_proxy.id
}
