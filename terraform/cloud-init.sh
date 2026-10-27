#!/bin/bash
# Runs once when the VM is first created: installs and starts nginx.
apt-get update -y
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx
# Let the admin user write the web root so Jenkins can deploy without sudo prompts
chown -R azureuser:azureuser /var/www/html
echo "<h1>Provisioned by Terraform - waiting for first Jenkins deploy</h1>" > /var/www/html/index.html
