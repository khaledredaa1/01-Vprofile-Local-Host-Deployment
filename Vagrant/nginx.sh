#!/bin/bash

# Update OS and install required packages
sudo apt-get update && sudo apt-get -y full-upgrade
sudo apt-get install -y nginx python3 curl lsb-release gnupg apt-transport-https ca-certificates software-properties-common

# Configure Nginx reverse proxy for vproapp
sudo tee /etc/nginx/sites-available/vproapp > /dev/null <<EOF
upstream vproapp {
    server app01:8080;
}

server {
    listen 80;
    location / {
        proxy_pass http://vproapp;
    }
}
EOF

# Enable vproapp site and disable default
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/vproapp /etc/nginx/sites-enabled/vproapp

# Start and enable Nginx
sudo systemctl enable nginx
sudo systemctl restart nginx

### --- nginx Exporter Setup ---

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

# Create exporter directory and navigate to it
CONFIG_DIR="/home/vagrant/nginx_exporter"
mkdir -p "$CONFIG_DIR"
cd "$CONFIG_DIR"

# Create Docker Compose file
cat <<EOL > docker-compose.yml
services:
  nginx_exporter:
    image: nginx/nginx-prometheus-exporter:latest
    container_name: nginx-exporter
    restart: unless-stopped
    ports:
      - "9113:9113"
EOL

# Set proper ownership for the Vagrant environment
sudo chown -R vagrant:vagrant "$CONFIG_DIR"

# Start the exporter as vagrant user
sudo -u vagrant docker compose up -d

# (Optional) Allow passwordless sudo for vagrant
echo 'vagrant ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/vagrant
