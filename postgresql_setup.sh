#!/bin/bash
# PostgreSQL setup script for Ubuntu EC2
# Usage: ./setup_postgres.sh [password]

set -e  # Exit immediately if a command exits with a non-zero status

# Parameters with defaults
PG_PASSWORD=${1:-"securepassword"} # Admin password
APP_USER=${2:-"todo_app"}         # Application username
APP_PASSWORD=${3:-"securepassword"} # Application password
PG_USER="postgres"                 # Default admin username
PG_DB="todos"                     # Database name

echo "=== Setting up PostgreSQL on Ubuntu ==="

# Update package lists
echo "=== Updating package lists ==="
sudo apt update

# Install PostgreSQL
echo "=== Installing PostgreSQL ==="
sudo apt install -y postgresql postgresql-contrib

# PostgreSQL service name and config directory
PG_SERVICE="postgresql"
PG_CONFIG_DIR="/etc/postgresql/$(ls /etc/postgresql/ | sort -V | tail -n1)/main"

# Start PostgreSQL service
echo "=== Starting PostgreSQL service ==="
sudo systemctl start $PG_SERVICE
sudo systemctl enable $PG_SERVICE

# Configure PostgreSQL to allow connections
echo "=== Configuring PostgreSQL ==="

# Backup the original pg_hba.conf file
sudo cp $PG_CONFIG_DIR/pg_hba.conf $PG_CONFIG_DIR/pg_hba.conf.bak

# Update pg_hba.conf to allow password authentication
sudo sed -i 's/local   all             postgres                                peer/local   all             postgres                                md5/' $PG_CONFIG_DIR/pg_hba.conf
sudo sed -i 's/local   all             all                                     peer/local   all             all                                     md5/' $PG_CONFIG_DIR/pg_hba.conf

# Add host connections for IPv4
echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a $PG_CONFIG_DIR/pg_hba.conf

# Modify postgresql.conf to listen on all interfaces
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $PG_CONFIG_DIR/postgresql.conf

# Restart PostgreSQL for changes to take effect
echo "=== Restarting PostgreSQL service ==="
sudo systemctl restart $PG_SERVICE

# Create the application database and user
echo "=== Creating database and user ==="
sudo -u postgres psql <<EOF
ALTER USER $PG_USER WITH PASSWORD '$PG_PASSWORD';
CREATE DATABASE $PG_DB;
CREATE USER $APP_USER WITH PASSWORD '$APP_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $PG_DB TO $APP_USER;
ALTER ROLE $APP_USER SET client_encoding TO 'utf8';
ALTER ROLE $APP_USER SET default_transaction_isolation TO 'read committed';
ALTER ROLE $APP_USER SET timezone TO 'UTC';
EOF

# Allow PostgreSQL through the firewall
sudo ufw allow 5432/tcp

echo "=== PostgreSQL setup completed ==="
echo "PostgreSQL version:"
psql --version

echo "=== Connection Information ==="
echo "Host: localhost or your-ec2-ip"
echo "Port: 5432"
echo "Database: $PG_DB"
echo "Admin Username: $PG_USER"
echo "Admin Password: $PG_PASSWORD"
echo "Application Username: $APP_USER"
echo "Application Password: $APP_PASSWORD"
echo ""
echo "Connection string format: postgresql://$APP_USER:$APP_PASSWORD@localhost:5432/$PG_DB"
echo ""
echo "Important: Make sure your EC2 security group allows inbound traffic on port 5432 for PostgreSQL connections."