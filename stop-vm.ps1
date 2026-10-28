# Stops (deallocates) the Azure VM so it doesn't use your Azure credit. The public IP stays the same.
az vm deallocate -g devopsia3-rg -n devopsia3-vm
Write-Host "VM stopped. Run start-project.ps1 to start it again." -ForegroundColor Green
