locals {
  packages = [
    "apt-transport-https",
    "build-essential",
    "ca-certificates",
    "curl",
    "jq",
    "lsb-release",
    "make",
    "python3-pip",
    "software-properties-common",
    "tmux",
    "tree",
    "unzip",
  ]
}

data "cloudinit_config" "_" {
  for_each = local.nodes

  part {
    filename     = "cloud-config.cfg"
    content_type = "text/cloud-config"
    content      = <<-EOF
      hostname: ${each.value.node_name}
      package_update: true
      package_upgrade: false
      packages:
      ${yamlencode(local.packages)}
      users:
      - default
      - name: docker
        primary_group: docker
        groups: docker
        home: /home/docker
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
        - ${tls_private_key.ssh.public_key_openssh}
        - ${join("\n", local.authorized_keys)}
      write_files:
      - path: /home/docker/.ssh/id_rsa
        defer: true
        owner: "docker:docker"
        permissions: "0600"
        content: |
          ${indent(4, tls_private_key.ssh.private_key_pem)}
      - path: /home/docker/.ssh/id_rsa.pub
        defer: true
        owner: "docker:docker"
        permissions: "0600"
        content: |
          ${indent(4, tls_private_key.ssh.public_key_openssh)}
      EOF
  }

  part {
    filename     = "allow-inbound-traffic.sh"
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/sh
      sed -i "s/-A INPUT -j REJECT --reject-with icmp-host-prohibited//" /etc/iptables/rules.v4
      netfilter-persistent start
      chown docker:docker /home/docker/.ssh/authorized_keys
    EOF
  }
}

data "http" "apt_repo_key" {
  url = "https://packages.cloud.google.com/apt/doc/apt-key.gpg.asc"
}
