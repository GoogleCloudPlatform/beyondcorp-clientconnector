// This file shows a sample input variable definitions file for the gateway set
// up.
// The input values shown here are not meant to be used as is.

credentials_file = "path/to/service_account_credentials.json"

project_id = "my-project"

vpc_network = "my-vpc-network"

customer_id = "my-customer-id"

// Multiple region deployment
regions = {
  "us-central1": {
    "subnetwork_cidr": "10.0.2.0/24",
    "mig_instance_count": 3
  },
  "us-west1": {
    "subnetwork_cidr": "10.0.3.0/24",
    "mig_instance_count": 2
  }
}

// These should cover the internal IPs where your applications are accessed.
private_subnets = ["192.168.0.0/24", "192.168.1.0/24"]

dh_params_pem_file = "path/to/dhparams.pem"