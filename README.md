
# Manual and Automated Provisioning of a Web App on Local Infrastructure Using Shell Scripts

## Description

This project demonstrates both **manual and automated provisioning** of a Java-based web application on **local infrastructure** using **Shell Scripts** and **Ansible**. It sets up a multi-tier architecture involving web, application, caching, messaging, and database layers, and includes a comprehensive **Prometheus** and **Grafana** monitoring system to collect, visualize, and alert on key metrics.

## Objectives

- **Build infrastructure from scratch**: Set up and integrate various services including web server, application server, database, caching, and message broker.
- **Automate provisioning**: Use Shell scripts and Ansible for automated, repeatable configurations.
- **Improve troubleshooting skills**: Address real-world errors and issues that arise during integration and configuration.
- **Centralized monitoring**: Collect metrics using Prometheus and visualize system/application health via Grafana.
- **Proactive alerting**: Configure alerts for quick identification of issues in the system.

## Tools Used

- **Vagrant** – Virtual machine management
- **VirtualBox/VMware** – Hypervisors
- **Tomcat** – Java application server
- **Nginx** – Reverse proxy and web server
- **RabbitMQ** – Messaging broker
- **Memcached** – In-memory caching system
- **MySQL (MariaDB)** – Relational database
- **Maven** – Java project build tool
- **Git** – Version control system
- **Ansible** – Automation and configuration management
- **Prometheus** – Time-series monitoring tool
- **Grafana** – Visualization and dashboarding
- **Exporters** – For exposing metrics (Node Exporter, MySQL Exporter, etc.)
- **Alertmanager (optional)** – Handles alerts from Prometheus

## Project Architecture

![Project Architecture](https://github.com/khaledredaa1/Screenshots/blob/main/Local%20Host%20Screenshots/SS01.PNG)

## Project Workflow

1. **Environment Setup**:
   - Install VirtualBox, Vagrant, and required plugins.

2. **VM Creation**:
   - Use Vagrant to spin up individual VMs for each service.

3. **Manual Provisioning**:
   - SSH into each VM and manually install services.

4. **Automated Provisioning**:
   - Run Shell scripts to automate installations and configurations.

5. **Service Integration**:
   - Link services together to build the end-to-end application stack.

6. **Monitoring Setup**:
   - Deploy Prometheus, Grafana, and exporters on dedicated VMs.

7. **Validation**:
   - Test application end-to-end and monitor system health via Grafana.

## Prerequisites

- Oracle VirtualBox
- Vagrant
- Vagrant plugins (e.g., `vagrant-hostmanager`)
- Git
- Bash Shell (e.g., Git Bash, WSL, Linux terminal)

## Manual Provisioning

Each VM is provisioned via Vagrant, and services are manually installed and configured via SSH.

## Automated Provisioning

Shell scripts are provided for each VM to automate installation/configuration of:

- Tomcat
- Nginx
- RabbitMQ
- Memcached
- MySQL (MariaDB)

## Getting Started

Clone the repository:

```bash
git clone https://github.com/khaledredaa1/Vprofile-Local-Host-Deployment.git
cd Vprofile-Local-Host-Deployment
```

Provision the VMs:

```bash
vagrant up
```

## Configuration Notes

- MySQL credentials: `admin` / `admin123`
- Memcached: port 11211
- RabbitMQ: port 5672
- Tomcat: port 8080
- Nginx reverse proxy: routes to `app01:8080`

## Ansible Structure

```
vprofile/
├── roles/
│   ├── mariadb_setup/
│   ├── memcached_setup/
│   ├── nginx_setup/
│   ├── rabbitmq_setup/
│   ├── tomcat_setup/
├── playbooks/
│   ├── mariadb_setup.yml
│   ├── memcached_setup.yml
│   ├── nginx_setup.yml
│   ├── rabbitmq_setup.yml
│   ├── tomcat_setup.yml
```

Each role contains tasks and handlers to automate service setup.

## Monitoring Stack

### Prometheus Setup

- Install Prometheus
- Add job targets for each exporter (e.g., `node_exporter`, `mysqld_exporter`, etc.)

### Exporters Used

- Node Exporter
- MySQL Exporter
- RabbitMQ Exporter
- Memcached Exporter
- JMX Exporter (for Tomcat)
- NGINX Exporter

### Grafana Setup

- Import dashboards (Node Exporter: ID `1860`, MySQL Exporter, etc.)
- Create custom dashboards and panels

### Alerting (Optional)

- Integrate Alertmanager
- Configure notification channels (e.g., Email, Slack)
- Define Prometheus alert rules

## Troubleshooting

### Vagrant Issues

- **VM fails to start**: Verify VirtualBox installation and Vagrant version.
- **Networking errors**: Ensure there are no IP conflicts and that host-only adapters are correctly configured.

### Service Issues

- **MySQL not accessible**:
  - Run `systemctl status mariadb`
  - Check for port binding issues or misconfigured `my.cnf`
  - Validate firewall and SELinux status

- **Web app not loading**:
  - Check Nginx configuration
  - Test Tomcat deployment manually at `http://app01:8080`

- **Metrics not appearing in Grafana**:
  - Confirm exporters are running (`systemctl status`)
  - Check Prometheus targets via `/targets` endpoint
  - Inspect Prometheus logs for scrape errors

- **Ansible failures**:
  - Use `ansible-playbook -vvv` for verbose output
  - Ensure inventory file and hostnames match Vagrant configurations

## Results

Screenshots from successful deployment:

![Login](https://github.com/khaledredaa1/Screenshots/blob/main/Local%20Host%20Screenshots/SS02.PNG)
![Home page](https://github.com/khaledredaa1/Screenshots/blob/main/Local%20Host%20Screenshots/SS03.PNG)
