#!/usr/bin/env bash
set -euo pipefail

############################################################################################
#inspiration from the RNCP lab w7d3
#dont want to run the same commands over and over 
# Plan: run the ansible playbook in the bastion 

## for host files- get the ips and key from tf output to build the host file
## 
## for playbook: i need docker, git in all, + db:posgres , app: redis ? , front end: nginx ?
### send al this to bastion and run it from there 

#### TO DO LIST
############## add to the machines sgs allow ssh from bastion, bastion can not connect to any machine ====>> adicionado como ingress aos sg o sg_bastion voltar a correr
############## provision in bastion to install ansible so that when exporting in this script, it just runs ansible
###-----------------------------------------------------------------------------

# 1. Provision with Terraform
cd terraform

## TO DO: find a way to not log directly in terminal, but save it in a file of sorts 
terraform init -upgrade
terraform apply -auto-approve
TF_OUTPUT_JSON=$(terraform output -json)          # capture outputs 
#outputs that needs to catch ips + key 

BASTION_IP=$(echo "$TF_OUTPUT_JSON"   | jq -r '.bastion_ip.value')
FRONTEND_IP=$(echo "$TF_OUTPUT_JSON"  | jq -r '.front_ip.value')
APP_IP=$(echo "$TF_OUTPUT_JSON"   | jq -r '.app_ip.value')
DATABASE_IP=$(echo "$TF_OUTPUT_JSON"  | jq -r '.db_ip.value')
##KEY_PATH=$(echo "$TF_OUTPUT_JSON"     | jq -r '.key_path.value')

echo "=== DEBUG TF OUTPUTS ==="
echo "BASTION_IP:  ${BASTION_IP}"
echo "FRONTEND_IP: ${FRONTEND_IP}"
echo "BACKEND_IP:  ${APP_IP}"
echo "DATABASE_IP: ${DATABASE_IP}"
echo "========================"
cd ..


## Build a One-Shot Inventory File
#### creating host files 

INV_FILE=$(mktemp)
cat > "$INV_FILE" <<EOF

[bastion]
bastion  ansible_host=${BASTION_IP} ansible_user=ubuntu ansible_private_key_file=/path/to/my_key.pem

[frontend]
frontend  ansible_host=${FRONTEND_IP} ansible_user=ubuntu ansible_private_key_file=/path/to/my_key.pem

[backend]
app ansible_host=${APP_IP} ansible_user=ubuntu ansible_private_key_file=/path/to/my_key.pem
db ansible_host=${DATABASE_IP} ansible_user=ubuntu ansible_private_key_file=/path/to/my_key.pem

EOF

ANSIBLE_CFG=$(mktemp --suffix=.cfg)


cat > "$ANSIBLE_CFG" <<EOF
[defaults]
inventory = ${INV_FILE}
host_key_checking = False
EOF


#debugging
echo "=== INV_FILE ($INV_FILE) ==="
cat "$INV_FILE"
echo "=== ANSIBLE_CFG ($ANSIBLE_CFG) ===" #=== ANSIBLE_CFG (/tmp/tmp.c3WZlY7dAw) === ANSIBLE_CFG was used as a env variable instead of file, therefore when exporting in line 30 error was given  
cat "$ANSIBLE_CFG"

cd ansible


##send to bation the host file, the ansible.cfg file and the playbook
scp -i ~/joaquim-labsg-key.pem $INV_FILE ubuntu@${BASTION_IP}:/home/ubuntu/inventory
scp -i ~/joaquim-labsg-key.pem "$ANSIBLE_CFG" ubuntu@${BASTION_IP}:/home/ubuntu/ansible.cfg
scp -i ~/joaquim-labsg-key.pem ansible/site.yml ubuntu@${BASTION_IP}:/home/ubuntu/site.yml
scp -i ~/joaquim-labsg-key.pem ~/joaquim-labsg-key.pem ubuntu@${BASTION_IP}:/home/ubuntu/

