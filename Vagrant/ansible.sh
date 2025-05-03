#!/bin/bash

# Install EPEL, Ansible, and Python
sudo dnf install -y epel-release
sudo dnf install -y ansible python3 dnf-plugins-core

# Configure Ansible
sudo bash -c 'cat <<EOF > /etc/ansible/ansible.cfg
[defaults]
remote_port       = 22
remote_user       = vagrant
host_key_checking = False
roles_path        = /home/vagrant/vproject

[privilege_escalation]
become          = True
become_method   = sudo
become_user     = root
become_ask_pass = False
EOF'

# Configure inventory file
sudo bash -c 'cat <<EOF > /etc/ansible/hosts
[vprofile]
db01
mc01
rmq01
app01
web01

[mariadb]
db01

[memcache]
mc01

[rabbitmq]
rmq01

[tomcat]
app01

[nginx]
web01

[monitor]
monitor01
EOF'

### --- node Exporter Setup ---

# Install Docker
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable --now docker

# Add vagrant user to docker group
sudo usermod -aG docker vagrant

# Create Node Exporter directory
CONFIG_DIR="/home/vagrant/node_exporter"
mkdir -p "$CONFIG_DIR"
cd "$CONFIG_DIR"

# Write docker-compose file
cat <<EOF > docker-compose.yml
services:
  node_exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - "9100:9100"
EOF

# Set ownership for vagrant (important if shared folder)
sudo chown -R vagrant:vagrant "$CONFIG_DIR"

# Start Node Exporter
sudo -u vagrant docker compose up -d

# Allow passwordless sudo for vagrant
echo 'vagrant ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/vagrant
