#!/usr/bin/env bash
set -euo pipefail

############################################################################################
#inspiration from the RNCP lab w7d3
#dont want to run the same commands over and over 
# Plan: run the ansible playbook in the bastion 

## for host files- get the ips and key from tf output to build the host file
## 
## for playbook: i need docker, git in all
### send al this to bastion and run it from there 

#### TO DO LIST
##############  when running at first, a host key check up is asked, even though the .cfg disregards it
##############  as of now its using the same key for all hosts, add a way to create a different key per host to increase security
##############  apply cloudwatch
##############  multi az scheme set up
###-----------------------------------------------------------------------------
export PATH=/usr/local/bin:/usr/bin:/snap/bin:$PATH

#for debugging, will be deleted upon final take
#echo "=== DEBUG AMBIENTE ==="
#echo "PWD: $(pwd)"
#echo "AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION:-não definido}"
#echo "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:-não definido}"
#echo "PATH: $PATH"
#which terraform
#which aws
#aws sts get-caller-identity
#echo "======================"
# 1. Provision with Terraform

cd ~/Project1_singleAZ/terraform

terraform init -upgrade
terraform apply -auto-approve
TF_OUTPUT_JSON=$(terraform output -json)          # capture outputs 
#outputs that needs to catch ips + key 

echo "---------Terraform finished : Infra created ---------------------------"

BASTION_IP=$(echo "$TF_OUTPUT_JSON"   | jq -r '.bastion_ip.value')
FRONTEND_IP=$(echo "$TF_OUTPUT_JSON"  | jq -r '.front_ip_priv.value')
APP_IP=$(echo "$TF_OUTPUT_JSON"   | jq -r '.app_ip.value')
DATABASE_IP=$(echo "$TF_OUTPUT_JSON"  | jq -r '.db_ip.value')
KEY="$HOME/joaquim-labsg-key.pem"
WEBSITE=$(echo "$TF_OUTPUT_JSON"   | jq -r '.front_ip_pub.value')

#echo "=== DEBUG TF OUTPUTS ==="
#echo "BASTION_IP:  ${BASTION_IP}"
#echo "FRONTEND_IP: ${FRONTEND_IP}"
#echo "BACKEND_IP:  ${APP_IP}"
#echo "DATABASE_IP: ${DATABASE_IP}"
#echo "========================"
cd ..

echo "  INFRASTRUCTURE CREATED ..... Starting up "

## Build a One-Shot Inventory File
#### creating host files 

INV_FILE=$(mktemp)
CMD_SSH_BASTION="ssh -i ${KEY} -W %h:%p -q ubuntu@${BASTION_IP}"  #add this in the inventory file to decrease repetition
cat > "$INV_FILE" <<EOF

[frontend]
frontend  ansible_host=${FRONTEND_IP} ansible_user=ubuntu ansible_private_key_file=${KEY}  StrictHostKeyChecking=no 

[backend]
app ansible_host=${APP_IP} ansible_user=ubuntu ansible_private_key_file=${KEY}  StrictHostKeyChecking=no 

[database]
db ansible_host=${DATABASE_IP} ansible_user=ubuntu ansible_private_key_file=${KEY}  StrictHostKeyChecking=no 

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


ANSIBLE_CONFIG="$ANSIBLE_CFG" ansible-playbook -i "$INV_FILE" ansible/bootstrap.yml

cat > ansible/vars.yml << EOF
database_ip: ${DATABASE_IP}
app_ip: ${APP_IP}
frontend_ip: ${FRONTEND_IP}
EOF

export ANSIBLE_HOST_KEY_CHECKING=False  # WIP just to make sure that does not request host key caching. It was asking in the first playbook runned      

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

## if need be, to debugg, de comment the next lines 
cd ~/Project1_singleAZ/terraform
terraform destroy -target=aws_instance.bastion -auto-approve




echo " VOTE: Click on this link  http://${WEBSITE}:8080/"
echo " RESULT: Click on this link  http://${WEBSITE}:8081/"