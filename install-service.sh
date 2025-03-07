#!/bin/bash

# Create service user
sudo useradd -r -s /bin/false etlservice

# Create application directory
sudo mkdir -p /opt/etldotnet
sudo mkdir -p /opt/etldotnet/logs/customers
sudo mkdir -p /opt/etldotnet/logs/orders
sudo mkdir -p /opt/etldotnet/state/orders

# Copy application files
sudo cp -r * /opt/etldotnet/

# Set permissions
sudo chown -R etlservice:etlservice /opt/etldotnet
sudo chmod -R 755 /opt/etldotnet

# Install service
sudo cp etldotnet.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable etldotnet
sudo systemctl start etldotnet

# Show status
sudo systemctl status etldotnet
