#!/bin/bash

# Install EPEL and required packages
sudo dnf install -y epel-release
sudo dnf install -y centos-release-rabbitmq-38 python3 dnf-plugins-core

# Enable RabbitMQ repo and install RabbitMQ
sudo dnf --enablerepo=centos-rabbitmq-38 install -y rabbitmq-server

# Start and enable RabbitMQ
sudo systemctl enable --now rabbitmq-server

# Configure RabbitMQ to allow remote connections
echo "[{rabbit, [{loopback_users, []}]}]." | sudo tee /etc/rabbitmq/rabbitmq.config
sudo systemctl restart rabbitmq-server

# Create RabbitMQ user with admin access
sudo rabbitmqctl add_user vprofile vprofile123
sudo rabbitmqctl set_user_tags vprofile administrator
sudo rabbitmqctl set_permissions -p / vprofile ".*" ".*" ".*"

# Open RabbitMQ port (5672) in firewall
sudo systemctl enable --now firewalld
sudo firewall-cmd --zone=public --add-port=5672/tcp --permanent
sudo firewall-cmd --reload

### --- rabbitmq Exporter Setup ---

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

# Create exporter directory and move into it
CONFIG_DIR="/home/vagrant/rabbitmq_exporter"
mkdir -p "$CONFIG_DIR"
cd "$CONFIG_DIR"

# Create Docker Compose file
cat <<EOF > docker-compose.yml
services:
  rabbitmq_exporter:
    image: kbudde/rabbitmq-exporter:latest
    container_name: rabbitmq-exporter
    restart: unless-stopped
    environment:
      RABBIT_URL: "http://192.168.56.30:15672"
      RABBIT_USER: "vprofile"
      RABBIT_PASSWORD: "vprofile123"
    ports:
      - "9419:9419"
EOF

# Set ownership for vagrant compatibility
sudo chown -R vagrant:vagrant "$CONFIG_DIR"

# Start exporter as vagrant
sudo -u vagrant docker compose up -d

# Optional: Allow passwordless sudo for vagrant
echo 'vagrant ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/vagrant
