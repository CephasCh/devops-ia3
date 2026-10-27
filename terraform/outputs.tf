output "public_ip" {
  description = "Public IP of the web server - put this in the Jenkinsfile (VM_IP)"
  value       = azurerm_public_ip.pip.ip_address
}

output "website_url" {
  value = "http://${azurerm_public_ip.pip.ip_address}"
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/devops_ia3 ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}
