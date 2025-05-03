#!/bin/bash

# Update and install Docker prerequisites
sudo apt-get update && sudo apt-get -y full-upgrade
sudo apt-get install -y python3 curl lsb-release gnupg apt-transport-https ca-certificates software-properties-common

# Install Docker & Docker Compose
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add vagrant user to Docker group
sudo usermod -aG docker vagrant

# Create configuration directory
CONFIG_DIR="/home/vagrant/monitor_config"
mkdir -p "$CONFIG_DIR"
cd "$CONFIG_DIR"

# Prometheus configuration
cat <<EOF > prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['192.168.56.70:9090']

  - job_name: 'mysql_exporter'
    static_configs:
      - targets: ['192.168.56.10:9104']

  - job_name: 'memcached_exporter'
    static_configs:
      - targets: ['192.168.56.20:9150']

  - job_name: 'rabbitmq_exporter'
    static_configs:
      - targets: ['192.168.56.30:9419']

  - job_name: 'jmx_exporter'
    static_configs:
      - targets: ['192.168.56.40:5556']

  - job_name: 'nginx_exporter'
    static_configs:
      - targets: ['192.168.56.50:9113']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['192.168.56.60:9100']
EOF

# Docker Compose configuration
cat <<EOL > docker-compose.yml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana

volumes:
  grafana_data:
EOL

# Change ownership for vagrant (important if running as root)
sudo chown -R vagrant:vagrant "$CONFIG_DIR"

# Start Prometheus and Grafana as vagrant user
sudo -u vagrant docker compose up -d

# Ensure passwordless sudo
echo 'vagrant ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/vagrant
