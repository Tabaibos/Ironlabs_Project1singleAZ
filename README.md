Single-AZ Voting App on AWS

Fully automated provisioning and configuration of a voting application (frontend + backend + database) in a single AWS Availability Zone, using Terraform for infrastructure and Ansible for configuration, orchestrated by a single shell script.

Goal

Automation and modularity: a single command creates the infrastructure, configures the hosts, and starts the application — no manual steps, and no unnecessary access left open at the end.

Architecture
                        ┌─────────────┐
   Internet ───────────▶│   Bastion   │  (public, temporary host)
                        └──────┬──────┘
                               │ SSH ProxyJump
              ┌────────────────┼────────────────┐
              ▼                ▼                 ▼
        ┌───────────┐   ┌────────────┐    ┌────────────┐
        │ Frontend  │   │  Backend   │    │  Database  │
        │  (Docker) │   │  (Docker)  │    │ (Postgres) │
        └───────────┘   └────────────┘    └────────────┘
         (private network — no public IP)

Frontend, Backend and Database live in private subnets, with no public IP.
The Bastion is the only SSH entry point, and is automatically created and destroyed on every run — it exists only for as long as Ansible needs to configure the other hosts.
All management traffic (Ansible/SSH) to the private instances goes through the bastion via SSH ProxyJump, never directly over the internet.
Technical highlight: ProxyJump through the Bastion

Since the frontend, backend and database have no public IP, access happens in two hops (a chained SSH connection through the bastion), configured automatically in the Ansible inventory:

ini
[backend:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -i <key> -W %h:%p -q ubuntu@<bastion_ip>"'

This means:

Ansible connects to the bastion and, from there, "jumps" (ProxyCommand/ProxyJump) to the target host, without ever exposing the private instances to the internet.
The local ssh-agent loads the key (ssh-add) once, avoiding the need to copy private keys into the bastion — safer and simpler to manage.
At the end of provisioning, the bastion is destroyed (terraform destroy -target=aws_instance.bastion)
Shell Automation

The setup_provision.sh script orchestrates the entire end-to-end flow:

Implementations:
Terraform — terraform init + terraform apply to create the whole infrastructure (bastion, frontend, backend, database) and capture the outputs (IPs) as JSON.
Dynamic inventory — generates a temporary Ansible inventory file (mktemp) with the IPs obtained from Terraform, already configured with per-group (frontend, backend, database) ProxyJump settings.
Dynamic Ansible config — also generates a temporary ansible.cfg (privilege escalation, host key checking disabled for this ephemeral environment).
ssh-agent — loads the required keys locally, enabling the jump through the bastion without copying private keys around.
Ansible playbooks, in this order:
bootstrap.yml — base host preparation
docker_db.yml — database container
docker_back.yml — backend container
docker_front.yml — frontend container
monotoring.yml — monitoring (WIP)
Automatic cleanup — destroys only the bastion (-target=aws_instance.bastion), keeping the rest of the infrastructure running.
Prints the final links to access the application (vote and result).

All of this runs with a single command, making the process repeatable and free of manual steps.

Project structure
Project1_singleAZ/
├── provision_s3/          # main.tf — creates S3 + DynamoDB for remote state (run once, first time only)
├── terraform/              # core infrastructure (bastion, frontend, backend, db)
│   └── terraform.tfvars    # created by you (see "Configuration" section)
├── ansible/
│   ├── bootstrap.yml
│   ├── docker_db.yml
│   ├── docker_back.yml
│   ├── docker_front.yml
│   ├── monotoring.yml      # WIP
│   └── secrets.yml         # created by you (see "Configuration" section)
└── setup_provision.sh
Prerequisites
AWS account
AWS CLI installed and configured
Terraform installed
Ansible installed
jq installed (used to parse Terraform outputs)
An existing key pair in the us-east-1 zone, used only for bastion access
Configuration
1) Remote state (first time only)
bash
cd provision_s3
terraform init
terraform apply

This creates the S3 bucket + DynamoDB table used to store the main infrastructure's state.

2) Terraform variables

Inside the terraform/ folder, create a terraform.tfvars file:

hcl
myIP     = "<your IP>/32"
key_name = "<name of an existing key pair in us-east-1>"
myIP — your public IP, required in /32 notation.
key_name — an existing AWS key pair (in the us-east-1 region), used only for SSH access to the bastion (which is destroyed at the end).
3) Ansible secrets

Inside the ansible/ folder, create a secrets.yml file:

yaml
pg_user: <insert username>
pg_password: <insert password>

Used to create/connect to the Postgres database.


Running it
./setup_provision.sh

At the end, the script prints the application's addresses:

VOTE:   http://<frontend-public-ip>:8080/
RESULT: http://<frontend-public-ip>:8081/
