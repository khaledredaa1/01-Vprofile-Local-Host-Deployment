#!/bin/bash

# Variables
TOMCAT_VERSION="9.0.75"
TOMCAT_USER="tomcat"
TOMCAT_INSTALL_DIR="/usr/local/tomcat"
TOMCAT_URL="https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"

# Install required packages
sudo dnf install -y epel-release
sudo dnf install -y java-11-openjdk java-11-openjdk-devel git maven wget firewalld python3 dnf-plugins-core

# Download and extract Apache Tomcat
cd /tmp/
wget $TOMCAT_URL -O tomcat.tar.gz
TOMDIR=$(tar -tf tomcat.tar.gz | head -1 | cut -d '/' -f1)
tar -xzf tomcat.tar.gz

# Create tomcat user and move files
if ! id "$TOMCAT_USER" &>/dev/null; then
  sudo useradd --home-dir $TOMCAT_INSTALL_DIR --shell /sbin/nologin $TOMCAT_USER
fi
sudo mkdir -p $TOMCAT_INSTALL_DIR
sudo cp -r /tmp/$TOMDIR/* $TOMCAT_INSTALL_DIR/
sudo chown -R $TOMCAT_USER:$TOMCAT_USER $TOMCAT_INSTALL_DIR

# Configure Tomcat as a systemd service
cat <<EOT | sudo tee /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
User=$TOMCAT_USER
Group=$TOMCAT_USER
Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk
Environment=CATALINA_HOME=$TOMCAT_INSTALL_DIR
Environment=CATALINA_BASE=$TOMCAT_INSTALL_DIR
ExecStart=$TOMCAT_INSTALL_DIR/bin/startup.sh
ExecStop=$TOMCAT_INSTALL_DIR/bin/shutdown.sh
ExecReload=$TOMCAT_INSTALL_DIR/bin/catalina.sh stop
Restart=always

[Install]
WantedBy=multi-user.target
EOT

# Start and enable the Tomcat service
sudo systemctl daemon-reload
sudo systemctl enable --now tomcat

# Open firewall for Tomcat
sudo systemctl enable --now firewalld
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
sudo firewall-cmd --reload

# Clone and build the vProfile app
cd /opt/
git clone -b main https://github.com/khaledredaa1/01-Vprofile-Local-Host-Deployment.git
cd 01-Vprofile-Local-Host-Deployment
sudo mvn install -DskipTests

# Deploy WAR to Tomcat
sudo systemctl stop tomcat
sudo rm -rf $TOMCAT_INSTALL_DIR/webapps/ROOT*
sudo cp target/vprofile-v2.war $TOMCAT_INSTALL_DIR/webapps/ROOT.war
sudo chown -R $TOMCAT_USER:$TOMCAT_USER $TOMCAT_INSTALL_DIR/webapps
sudo systemctl start tomcat

# Clean up
rm -f /tmp/tomcat.tar.gz

### --- JMX Exporter Setup ---

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

# Setup JMX Exporter
CONFIG_DIR="/home/vagrant/jmx_exporter"
mkdir -p "$CONFIG_DIR"
cd "$CONFIG_DIR"

# Docker Compose for JMX Exporter
cat <<EOF > docker-compose.yml
services:
  jmx-exporter:
    image: bitnami/jmx-exporter:latest
    container_name: jmx_exporter
    environment:
      - JMX_HOST=127.0.0.1                                  # Application host
      - JMX_PORT=5556                                       # Application JMX port
      - JVM_OPTS=-Xms512m -Xmx512m
    ports:
      - "5556:5556"                                         # Exposing JMX Exporter port
    volumes:
      - ./config.yml:/opt/bitnami/jmx-exporter/conf/config.yml
    restart: unless-stopped
EOF

# JMX Exporter config file
cat <<EOF > config.yml
---
startDelaySeconds: 0
hostPort: 127.0.0.1:5556                                    # Application host:Application JMX port
ssl: false
lowercaseOutputName: true
lowercaseOutputLabelNames: true
whitelistObjectNames:
  - "java.lang:type=Memory"
  - "java.lang:type=GarbageCollector,name=*"
EOF

# Set correct permissions
sudo chown -R vagrant:vagrant "$CONFIG_DIR"

# Start JMX Exporter
sudo -u vagrant docker compose up -d

# Enable passwordless sudo for vagrant (optional for Vagrant automation)
echo 'vagrant ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/vagrant
