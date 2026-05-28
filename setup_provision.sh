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
export PATH=/usr/local/bin:/usr/bin:/snap/bin:$PATH

echo "=== DEBUG AMBIENTE ==="
echo "PWD: $(pwd)"
echo "AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION:-não definido}"
echo "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:-não definido}"
echo "PATH: $PATH"
which terraform
which aws
aws sts get-caller-identity
echo "======================"
# 1. Provision with Terraform
cd ~/Project1_singleAZ/terraform


## TO DO: find a way to not log directly in terminal, but save it in a file of sorts 
terraform init -upgrade
terraform apply -auto-approve
TF_OUTPUT_JSON=$(terraform output -json)          # capture outputs 
#outputs that needs to catch ips + key 

echo "---------Terraform finished : Infra created ---------------------------"

BASTION_IP=$(echo "$TF_OUTPUT_JSON"   | jq -r '.bastion_ip.value')
FRONTEND_IP=$(echo "$TF_OUTPUT_JSON"  | jq -r '.front_ip_priv.value')
APP_IP=$(echo "$TF_OUTPUT_JSON"   | jq -r '.app_ip.value')
DATABASE_IP=$(echo "$TF_OUTPUT_JSON"  | jq -r '.db_ip.value')
#KEY=$(echo "$TF_OUTPUT_JSON" | jq -r '.key_path.value')
KEY="$HOME/joaquim-labsg-key.pem"
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
CMD_SSH_BASTION="ssh -i ${KEY} -W %h:%p -q ubuntu@${BASTION_IP}"
cat > "$INV_FILE" <<EOF

[frontend]
frontend  ansible_host=${FRONTEND_IP} ansible_user=ubuntu ansible_private_key_file=${KEY}

[backend]
app ansible_host=${APP_IP} ansible_user=ubuntu ansible_private_key_file=${KEY}
db ansible_host=${DATABASE_IP} ansible_user=ubuntu ansible_private_key_file=${KEY}

[frontend:vars]
ansible_ssh_common_args= '-o ProxyCommand="ssh -i ${KEY} -W %h:%p -q ubuntu@${BASTION_IP}"'

[backend:vars]
ansible_ssh_common_args= '-o ProxyCommand="ssh -i ${KEY} -W %h:%p -q ubuntu@${BASTION_IP}"'
EOF

ANSIBLE_CFG=$(mktemp --suffix=.cfg)


cat > "$ANSIBLE_CFG" <<EOF
[defaults]
inventory = "/home/ubuntu/inventory"
host_key_checking = False

[privilege_escalation]
become = True
become_method = sudo
become_user = root
EOF

# running with local agent ssh-agent
eval $(ssh-agent -s)
ssh-add "$KEY"

echo "=== INV_FILE (${INV_FILE}) ==="
cat "$INV_FILE"
echo ""
echo "=== ANSIBLE_CFG (${ANSIBLE_CFG}) ==="
cat "$ANSIBLE_CFG"
echo ""

ANSIBLE_CONFIG="$ANSIBLE_CFG" ansible-playbook -i "$INV_FILE" ansible/site.yml