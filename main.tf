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

terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 3.38"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 3.0"
    }
  }
  required_version = ">= 0.13.0"
}

provider "google" {
  project     = var.project_id
  credentials = file(var.credentials_file)
}
provider "google-beta" {
  project     = var.project_id
  credentials = file(var.credentials_file)
}
provider "tls" {}

################################ Local vars ####################################

locals {
  # Naming prefix.
  prefix = "bce-clientconnector"
  # Port serving requests.
  service_port = 443
  # Tag to group gateway instances.
  gateway_ia_tag = "bce-clientconnector-gateway-ia"
  # Producer project
  producer_project_id = "bce-client-connector-preview"
}

############################## API Enablement ##################################

# Ensures Compute API is enabled for the project.
resource "google_project_service" "compute_api" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

################################ Subnetworks ###################################

# Creates a subnet per specified region for deploying Client Connector gateway
# resources into.
resource "google_compute_subnetwork" "gateway_subnet" {
  for_each      = var.regions
  name          = "${local.prefix}-subnet-${each.key}"
  ip_cidr_range = var.regions[each.key].subnetwork_cidr
  network       = var.vpc_network
  region        = each.key
  # Needed for gcr access in the absence of public IP.
  private_ip_google_access = true
}

########################### Managed Instance Group #############################

# Configure managed instance groups hosting the gateway.
module "mig" {
  source       = "./modules/mig"
  project_id   = var.project_id
  prefix       = local.prefix
  service_port = local.service_port
  ia_tag       = local.gateway_ia_tag
  cert_params = {
    ca_cert_pem        = module.certificate.ca_cert_pem
    server_cert_pem    = module.certificate.server_cert_pem,
    server_pk_pem      = module.certificate.server_pk_pem,
    dh_params_pem_file = var.dh_params_pem_file
  }
  regions = {
    for key in keys(google_compute_subnetwork.gateway_subnet) : key => {
      subnetwork_name    = google_compute_subnetwork.gateway_subnet[key].name
      mig_instance_count = var.regions[key].mig_instance_count
    }
  }
}

############################## Load Balancer ###################################

# Configure the load balancer to front gateway instances.
module "lb" {
  source       = "./modules/loadbalancer"
  project_id   = var.project_id
  prefix       = local.prefix
  vpc_network  = var.vpc_network
  service_port = local.service_port
  ia_tag       = local.gateway_ia_tag
  backend_ia_groups = [
    for value in values(module.mig.regional_migs) : value.instance_group
  ]
  enable_ipv6_forwarding = var.enable_ipv6_clients
}

################################ Server Cert ###################################

# Fetch the certificates needed to deploy the gateway.
module "certificate" {
  source = "./modules/certificate"
}

########################## Storing client parameters ###########################

# Store connection parameters needed by gateway clients.
module "storage" {
  source              = "./modules/storage"
  producer_project_id = local.producer_project_id
  prefix              = local.prefix
  customer_id         = var.customer_id
  service_port        = local.service_port
  client_params = {
    remote_ipv4_addresses = module.lb.ipv4_addresses
    remote_ipv6_addresses = module.lb.ipv6_addresses
    ca_cert_pem           = module.certificate.ca_cert_pem
    private_subnets       = var.private_subnets
  }
}

################################################################################
