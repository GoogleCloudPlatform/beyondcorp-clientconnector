#cloud-config
# vim: syntax=yaml
#
# This configuration is used to initialize the GCE VMs running BCE Client
# Connector gateway servers.
#

write_files:
  # Stores certificates and keys needed to configure OpenVPN server.
  - path: /etc/openvpn/server/pki/ca.pem
    permissions: 0644
    content: |
      ${indent(6, "${ca_pem}")}
  - path: /etc/openvpn/server/pki/issued/server_cert.pem
    permissions: 0644
    content: |
      ${indent(6, "${server_cert_pem}")}
  - path: /etc/openvpn/server/pki/private/server_key.pem
    permissions: 0644
    content: |
      ${indent(6, "${server_pk_pem}")}
  - path: /etc/openvpn/server/pki/private/dh_params.pem
    permissions: 0644
    content: |
      ${indent(6, "${dh_params_pem}")}
  # Configures the host firewall as follows:
  # - Allows http (80), https (443) and ssh (22) traffic.
  # - Sets up Source NAT and IP forwarding.
  - path: /etc/systemd/system/firewall.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Configures the host firewall

      [Service]
      Type=oneshot
      RemainAfterExit=true
      ExecStart=\
      /sbin/iptables -t nat -I POSTROUTING -o eth0 -s 100.89.24.0/25 -j MASQUERADE ; \
      /sbin/iptables -P FORWARD ACCEPT ; \
      /sbin/iptables -A INPUT -p tcp --dport 22 -j ACCEPT ; \
      /sbin/iptables -A INPUT -p tcp --dport 80 -j ACCEPT ; \
      /sbin/iptables -A INPUT -p tcp --dport 443 -j ACCEPT ;
  # Configures the Gateway (OpenVPN) server, running the docker image.
  - path: /etc/systemd/system/gateway.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Gateway service
      After=docker.service firewall.service
      Wants=docker.service firewall.service

      [Service]
      Restart=on-failure
      Environment="HOME=/home/gatewayservice"
      ExecStartPre=/usr/bin/docker-credential-gcr configure-docker
      ExecStart=\
      /usr/bin/docker run \
        --name=gatewayserver \
        -v /etc/openvpn/server/:/server/ \
        --net=host \
        --cap-add=NET_ADMIN \
        --device=/dev/net/tun \
        gcr.io/bce-client-connector-preview/gateway:latest ;
      ExecStop=/usr/bin/docker stop gatewayserver
      ExecStopPost=/usr/bin/docker rm gatewayserver

runcmd:
  - systemctl daemon-reload
  - systemctl enable gateway.service
  - systemctl start gateway.service
