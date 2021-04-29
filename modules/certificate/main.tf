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

# Create a key pair for CA.
resource "tls_private_key" "ca_pk" {
  algorithm = "RSA"
}

# Create a self-signed CA.
resource "tls_self_signed_cert" "ca_cert" {
  key_algorithm   = tls_private_key.ca_pk.algorithm
  private_key_pem = tls_private_key.ca_pk.private_key_pem

  # Required field.
  subject {
    common_name  = "privatepreview.bceclientconnector.com"
    organization = "BeyondCorp Enterprise Client Connector"
  }

  # Set to a large value so we don't have to worry about expiring CA.
  validity_period_hours = 24 * 365 * 3 # 3 years

  allowed_uses = [
    "cert_signing",
    "crl_signing"
  ]

  is_ca_certificate = true
}

# Create a key pair for server certificate.
resource "tls_private_key" "server_pk" {
  algorithm = "RSA"
}

# Create a certificate signing request.
resource "tls_cert_request" "server_csr" {
  key_algorithm   = tls_private_key.server_pk.algorithm
  private_key_pem = tls_private_key.server_pk.private_key_pem

  # Required field.
  # The values don't really matter as clients don't use a FQDN to connect to
  # the server.
  subject {
    common_name  = "gateway.privatepreview.bceclientconnector.com"
    organization = "BeyondCorp Enterprise Client Connector"
  }
}

# Create a self-signed server certificate.
resource "tls_locally_signed_cert" "server_cert" {
  cert_request_pem   = tls_cert_request.server_csr.cert_request_pem
  ca_key_algorithm   = tls_private_key.ca_pk.algorithm
  ca_private_key_pem = tls_private_key.ca_pk.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  # Set to a large value so we don't have to worry about expiring certs.
  validity_period_hours = 24 * 365 * 2 # 2 years

  # As per OpenVPN documentation.
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}
