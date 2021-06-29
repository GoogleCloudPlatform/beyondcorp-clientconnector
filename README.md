# BeyondCorp Enterprise Client Connector Terraform Module

Google’s BeyondCorp Enterprise (BCE) Client Connector allows customers to secure
non-http workloads resident in non-GCP environments. A common use case is to
secure legacy client-server applications with context-aware checks.

**Note:** The product is currently available as a Private Preview offering. You
can reach out to your Account Team for gaining access.

This document provides a step-by-step walk-through of deploying the gateway
component responsible for tunneling the user traffic to the applications. Please
refer to the user guide for setting up other components (ex. client).

The gateway comprises the following high-level resources:

-   Regional Managed Instance Groups (MIGs): deployed per-region as configured
    by the customer.

-   OpenVPN server: runs on instances. Responsible for authorizing client
    connections and forwarding traffic to destination remote subnets.

-   External Global TCP Proxy Load Balancer: exposes a global static IP address
    for clients to connect to and balances traffic across backend MIGs.

The solution uses Terraform to actuate the above resources.

## Key Inputs

| Name                | Description                       | Default | Required |
| ------------------- | --------------------------------- | :-----: | :------: |
| credentials_file    | Key file of the service account used to authenticate | n/a     | yes      |
| project_id          | The project to deploy to          | n/a     | yes      |
| vpc_network         | The VPC network to deploy to      | n/a     | yes      |
| customer_id         | The Google Workspace customer id  | n/a     | yes      |
| regions             | Configuration of regions to deploy to | n/a     | yes      |
| dh_params_pem_file  | Diffie-Hellman parameters to configure server | n/a     | yes      |
| private_subnets     | The destination subnets to tunnel traffic to | n/a     | yes      |
| enable_ipv6_clients | Enable traffic from IPv6 clients  | false   | no       |

**Note:** The customer id should be provided without the leading "C" (if present).

## Prerequisites

-   Terraform version >= 0.13

-   OpenSSL

-   Cloud VPN connection between a GCP project and the remote environment
    (onprem or another cloud).

    If you don't have one configured, then do the following:

    1.  [Create a new project and set up billing](https://cloud.google.com/resource-manager/docs/creating-managing-projects).

        ```
        gcloud projects create [PROJECT_ID]
        gcloud beta billing projects link [PROJECT_ID] --billing-account=[ACCOUNT_ID]
        ```

    1.  [Configure Cloud VPN](https://cloud.google.com/network-connectivity/docs/vpn/how-to/creating-ha-vpn)
        in a custom VPC network.

## Deployment Steps

The "project" and "vpc_network" referred in the steps below are the GCP project
and the custom VPC network, respectively, configured with the Cloud VPN
connection. See [Prerequisites](#prerequisites).

1.  Enable the following APIs in the project:

    -   [Compute Engine API](https://console.cloud.google.com/apis/library/compute.googleapis.com)
    -   [Cloud Resource Manager API](https://console.cloud.google.com/apis/library/cloudresourcemanager.googleapis.com)

    ```
    gcloud services enable compute.googleapis.com
    gcloud services enable cloudresourcemanager.googleapis.com
    ```

1.  Get the
    [default service account](https://cloud.google.com/compute/docs/access/service-accounts#default_service_account)
    for your Compute Engine resources. This is automatically created when you
    enable the Compute Engine API. You can find it under Credentials or your
    project's IAM page in Cloud Console.

1.  [Create a service account](https://cloud.google.com/iam/docs/creating-managing-service-accounts#iam-service-accounts-create-gcloud).
    This is the account that will be used to authenticate with GCP when running
    the terraform script.

1.  Share the default Compute Engine and self-created service accounts with
    Google for permission provisioning, according to the onboarding process
    described in the user guide.

1.  Assign Compute Admin IAM role to the created service account.

    ```
    gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:SERVICE_ACCOUNT_ID@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.admin"
    ```

1.  Assign
    [Service Account User](https://cloud.google.com/iam/docs/impersonating-service-accounts#iam-service-accounts-grant-role-sa-console)
    role to the created service account on the Compute Engine default service
    account.

    ```
    gcloud iam service-accounts add-iam-policy-binding PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --member="serviceAccount:SERVICE_ACCOUNT_ID@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"
    ```

1.  Generate the Diffie-Hellman key used to configure the server.

    ```
    openssl dhparam -out dhparams.pem 2048
    ```

1.  Run terraform to actuate resources. FILEPATH is the `.tfvars` file
    containing the [input variables](#key-inputs).

    ```
    terraform apply -var-file=[FILEPATH]
    ```
