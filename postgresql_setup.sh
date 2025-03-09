#!/bin/bash
# PostgreSQL setup script for Ubuntu EC2
# Usage: ./postgresql_setup.sh [admin_password] [app_user] [app_password]

set -e  # Exit immediately if a command exits with a non-zero status

# Parameters with defaults
PG_PASSWORD=${1:-"securepassword"}
PG_DB="todos"

echo "=== Setting up PostgreSQL on Ubuntu ==="

echo "=== Updating package lists ==="
sudo apt-get update

echo "=== Installing PostgreSQL ==="
sudo apt install -y postgresql

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

# Add host connections for IPv4
echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a $PG_CONFIG_DIR/pg_hba.conf

# Modify postgresql.conf to listen on all interfaces
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $PG_CONFIG_DIR/postgresql.conf

# Create the application database and user
echo "=== Creating database and user ==="

# Use sudo to run commands as postgres user - no password needed with peer auth
sudo -u postgres psql << EOF
  ALTER USER postgres WITH PASSWORD '$PG_PASSWORD';
  CREATE DATABASE $PG_DB;
EOF

# Now update pg_hba.conf for password auth after we've set passwords
sudo sed -i 's/local   all             postgres                                peer/local   all             postgres                                md5/' $PG_CONFIG_DIR/pg_hba.conf
sudo sed -i 's/local   all             all                                     peer/local   all             all                                     md5/' $PG_CONFIG_DIR/pg_hba.conf

# Restart PostgreSQL for changes to take effect
echo "=== Restarting PostgreSQL service ==="
sudo systemctl restart $PG_SERVICE

# Allow PostgreSQL through the firewall
sudo ufw allow 5432/tcp 2>/dev/null || echo "Firewall rule not added (ufw may not be enabled)"

echo "=== PostgreSQL setup completed ==="
echo "PostgreSQL version:"
psql --version || echo "psql command not available in PATH"

# Test the connection with the new password
echo "=== Testing the connection ==="
PGPASSWORD="$PG_PASSWORD" psql -h localhost -U postgres -c "SELECT 'PostgreSQL connection working' AS status;" 2>/dev/null || echo "Connection test failed - this is expected if this is the first setup, try again after restart"