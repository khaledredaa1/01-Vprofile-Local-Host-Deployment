#!/bin/bash

# Install required packages
sudo dnf install -y epel-release
sudo dnf install -y memcached firewalld python3 dnf-plugins-core

# Start and enable Memcached
sudo systemctl enable --now memcached

# Allow Memcached to listen on all interfaces (for external access)
sudo sed -i 's/^OPTIONS="-l 127.0.0.1"/OPTIONS="-l 0.0.0.0"/' /etc/sysconfig/memcached
sudo systemctl restart memcached

# Enable firewall and open required ports
sudo systemctl enable --now firewalld
sudo firewall-cmd --permanent --add-port=11211/tcp
sudo firewall-cmd --reload

### --- memcached Exporter Setup ---

# Install Docker
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable --now docker

# Check Docker status
if ! systemctl is-active --quiet docker; then
  echo "Docker installation failed or Docker is not running."
  exit 1
fi

# Add vagrant user to docker group
sudo usermod -aG docker vagrant

# Setup Memcached Exporter
CONFIG_DIR="/home/vagrant/memcached_exporter"
mkdir -p "$CONFIG_DIR"
cd "$CONFIG_DIR"

cat <<EOF > docker-compose.yml
services:
  memcached_exporter:
    image: prom/memcached-exporter:latest
    container_name: memcached_exporter
    restart: unless-stopped
    ports:
      - "9150:9150"
EOF

# Ensure correct ownership for Vagrant shared folder compatibility
sudo chown -R vagrant:vagrant "$CONFIG_DIR"

# Start Memcached Exporter using Docker Compose
sudo -u vagrant docker compose up -d

# Allow passwordless sudo for vagrant (optional but useful)
echo 'vagrant ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/vagrant
