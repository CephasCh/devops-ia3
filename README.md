# DevOps IA3 – Automated Deployment with Terraform, Azure & Jenkins

A static HTML/CSS web app is deployed to an Azure Linux VM (nginx).
Terraform provisions the infrastructure; a Jenkins pipeline checks out the code
from GitHub, builds it, and deploys it to the VM on every commit (Poll SCM).

```
Developer --push--> GitHub --poll (2 min)--> Jenkins --scp/ssh--> Azure VM (nginx) --> Browser
                                               ^
Terraform --provisions--> RG, VNet, Subnet, NSG, Public IP, NIC, VM
```

## Repository layout

| Path | Purpose |
|------|---------|
| `terraform/main.tf` | Resource Group, VNet, Subnet, Public IP, NSG, NIC, Linux VM |
| `terraform/variables.tf` | Inputs (subscription, region, VM size, SSH key) |
| `terraform/outputs.tf` | Public IP, website URL, SSH command |
| `terraform/cloud-init.sh` | Installs nginx on first boot |
| `app/` | The web application (index.html, style.css) |
| `Jenkinsfile` | Checkout → Build → Deploy → Verify pipeline |

---

## Setup steps (Windows)

### 0. Install tools
- Git, Azure CLI, Terraform, Java 21 (Temurin), Jenkins LTS
  ```powershell
  winget install Git.Git Microsoft.AzureCLI Hashicorp.Terraform EclipseAdoptium.Temurin.21.JDK Jenkins.Jenkins
  ```

### 1. Create an SSH key for the VM
```powershell
ssh-keygen -t rsa -b 4096 -m PEM -f $HOME\.ssh\devops_ia3 -N '""'
```

### 2. Provision Azure with Terraform
```powershell
az login
az account show --query id -o tsv      # copy your subscription ID
cd terraform
copy terraform.tfvars.example terraform.tfvars   # paste the ID into it
terraform init
terraform validate
terraform plan
terraform apply                          # type 'yes'  -> screenshot this
terraform output public_ip
```
Open `http://<public_ip>` – you should see "Provisioned by Terraform".

### 3. Push to GitHub
Put the public IP into `VM_IP` in the `Jenkinsfile`, then:
```powershell
git init
git add .
git commit -m "Initial commit: Terraform, Jenkinsfile, web app"
git branch -M main
git remote add origin https://github.com/<you>/devops-ia3.git
git push -u origin main
```

### 4. Configure Jenkins (http://localhost:8080)
1. Install suggested plugins (includes Git + Pipeline). Also install **Credentials Binding** if missing.
2. *Manage Jenkins → Credentials → System → Global → Add Credentials*
   - Kind: **SSH Username with private key**
   - ID: `azure-vm-ssh`
   - Username: `azureuser`
   - Private key: *Enter directly* → paste the contents of `%USERPROFILE%\.ssh\devops_ia3`
3. *New Item → Pipeline* named `devops-ia3`
   - **Build Triggers:** tick *Poll SCM*, schedule `H/2 * * * *`
   - **Pipeline:** *Pipeline script from SCM* → Git → your repo URL → branch `*/main` → Script Path `Jenkinsfile`
4. Click **Build Now** once (this also registers the poll trigger) → screenshot the Stage View.

### 5. Demonstrate continuous deployment
Change `Version 1` to `Version 2` in `app/index.html`, commit and push.
Within ~2 minutes Jenkins builds automatically and the page updates.

### 6. Clean up (avoid Azure charges)
```powershell
cd terraform
terraform destroy
```
