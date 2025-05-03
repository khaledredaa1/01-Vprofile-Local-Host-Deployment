#!/bin/bash

# Variables
DATABASE_PASS='admin123'
DB_USER='admin'
DB_NAME='accounts'
REPO_URL='https://github.com/khaledredaa1/01-Vprofile-Local-Host-Deployment.git'
DB_DUMP_PATH='src/main/resources/db_backup.sql'

# Install required packages
sudo dnf install -y epel-release
sudo dnf install -y git zip unzip mariadb-server firewalld python3 dnf-plugins-core

# Start and enable MariaDB
sudo systemctl enable --now mariadb

# Ensure MariaDB has fully initialized before changing the root password
sleep 5

# Set root password and secure MariaDB
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DATABASE_PASS}';"
sudo mysql -u root -p"${DATABASE_PASS}" <<EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db LIKE 'test%';
FLUSH PRIVILEGES;
EOF

# Create database and user with remote access
sudo mysql -u root -p"${DATABASE_PASS}" <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DATABASE_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%' IDENTIFIED BY '${DATABASE_PASS}';
FLUSH PRIVILEGES;
EOF

# Clone repo and import SQL dump
cd /tmp
git clone -b main ${REPO_URL}
sudo mysql -u root -p"${DATABASE_PASS}" ${DB_NAME} < /tmp/01-Vprofile-Local-Host-Deployment/${DB_DUMP_PATH}

# Clean up
sudo rm -rf /tmp/01-Vprofile-Local-Host-Deployment

# Configure firewall
sudo systemctl enable --now firewalld
sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --reload

# Restart MariaDB to apply all settings
sudo systemctl restart mariadb

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

# Setup Memcached Exporter (still in this VM?)
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

# Set correct permissions
sudo chown -R vagrant:vagrant "$CONFIG_DIR"

# Start Docker Compose as vagrant
sudo -u vagrant docker compose up -d

# Allow passwordless sudo for vagrant
echo 'vagrant ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/vagrant
