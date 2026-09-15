#!/usr/bin/env bash
set -euo pipefail

# version 1.0.15
# author: Joaquim Almeida 

export PATH=/usr/local/bin:/usr/bin:/snap/bin:$PATH


# Provision with Terraform

cd ~/Project1_singleAZ/terraform

terraform init -upgrade
terraform apply -auto-approve
TF_OUTPUT_JSON=$(terraform output -json)          # capture outputs 


echo "---------Terraform finished : Infra created ---------------------------"

BASTION_IP=$(echo "$TF_OUTPUT_JSON"   | jq -r '.bastion_ip.value')
FRONTEND_IP=$(echo "$TF_OUTPUT_JSON"  | jq -r '.front_ip_priv.value')
APP_IP=$(echo "$TF_OUTPUT_JSON"   | jq -r '.app_ip.value')
DATABASE_IP=$(echo "$TF_OUTPUT_JSON"  | jq -r '.db_ip.value')
KEY="$HOME/joaquim-labsg-key.pem"
WEBSITE=$(echo "$TF_OUTPUT_JSON"   | jq -r '.front_ip_pub.value')
FRONTEND_KEY=$(echo "$TF_OUTPUT_JSON" | jq -r '.frontend_key_path.value')
BACKEND_KEY=$(echo "$TF_OUTPUT_JSON"  | jq -r '.backend_key_path.value')
DATABASE_KEY=$(echo "$TF_OUTPUT_JSON" | jq -r '.database_key_path.value')

cd ..

echo "  INFRASTRUCTURE CREATED ..... Starting up "

## Build a One-Shot Inventory File

INV_FILE=$(mktemp)
CMD_SSH_BASTION="ssh -i ${KEY} -W %h:%p -q ubuntu@${BASTION_IP}" 
cat > "$INV_FILE" <<EOF

[frontend]
front ansible_host=${FRONTEND_IP} ansible_user=ubuntu ansible_private_key_file=${FRONTEND_KEY}  StrictHostKeyChecking=no 

[backend]
app ansible_host=${APP_IP} ansible_user=ubuntu ansible_private_key_file=${BACKEND_KEY}  StrictHostKeyChecking=no 

[database]
db ansible_host=${DATABASE_IP} ansible_user=ubuntu ansible_private_key_file=${DATABASE_KEY}  StrictHostKeyChecking=no 

[frontend:vars]
host_role=frontend
ansible_ssh_common_args='-o ProxyCommand="ssh -i ${KEY} -W %h:%p -q ubuntu@${BASTION_IP}"'

[backend:vars]
host_role=backend
ansible_ssh_common_args='-o ProxyCommand="ssh -i ${KEY} -W %h:%p -q ubuntu@${BASTION_IP}"'

[database:vars]
host_role=database
ansible_ssh_common_args='-o ProxyCommand="ssh -i ${KEY} -W %h:%p -q ubuntu@${BASTION_IP}"'

EOF

ANSIBLE_CFG=$(mktemp --suffix=.cfg)


#setinf the ansible.cfg file / inventory file was created above with INV_FILE
cat > "$ANSIBLE_CFG" <<EOF
[defaults]
host_key_checking = False

[privilege_escalation]
become = True
become_method = sudo
become_user = root
EOF

# running with local agent ssh-agent for proxyjump. Removes the need to copy the key into bastion
eval $(ssh-agent -s)
ssh-add "$KEY"
ssh-add "$FRONTEND_KEY"
ssh-add "$BACKEND_KEY"
ssh-add "$DATABASE_KEY"


ANSIBLE_CONFIG="$ANSIBLE_CFG" ansible-playbook -i "$INV_FILE" ansible/bootstrap.yml

cat > ansible/vars.yml << EOF
database_ip: ${DATABASE_IP}
app_ip: ${APP_IP}
frontend_ip: ${FRONTEND_IP}
EOF

export ANSIBLE_HOST_KEY_CHECKING=False       

echo "=== Setting up container for db ==="
ANSIBLE_CONFIG="$ANSIBLE_CFG" ansible-playbook -i "$INV_FILE" ansible/docker_db.yml

echo "=== Setting up container for back host ==="
ANSIBLE_CONFIG="$ANSIBLE_CFG" ansible-playbook -i "$INV_FILE" ansible/docker_back.yml

echo "=== Setting up container for front host ==="
ANSIBLE_CONFIG="$ANSIBLE_CFG" ansible-playbook -i "$INV_FILE" ansible/docker_front.yml

echo "=== (WIP) Setting up monotoring for front host ==="
ANSIBLE_CONFIG="$ANSIBLE_CFG" ansible-playbook -i "$INV_FILE" ansible/monotoring.yml ## WIP disregard command if needed

# FOR DEBUG ONLY
#for manual debugging purposes at first try decoment the next line. Bastion can keep this key because it will eventually be deleted
#scp -i ~/joaquim-labsg-key.pem ~/joaquim-labsg-key.pem ubuntu@${BASTION_IP}:/home/ubuntu

## if need be, to debugg, comment the next lines 
cd ~/Project1_singleAZ/terraform
terraform destroy -target=aws_instance.bastion -auto-approve


echo " VOTE: Click on this link  http://${WEBSITE}:8080/"
echo " RESULT: Click on this link  http://${WEBSITE}:8081/"